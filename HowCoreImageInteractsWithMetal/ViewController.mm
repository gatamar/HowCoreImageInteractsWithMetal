//
//  ViewController.m
//  HowCoreImageInteractsWithMetal
//
//  Created by Olha Pavliuk on 27.10.2020.
//  Copyright © 2020 test. All rights reserved.
//

#import "ViewController.h"
#import <Metal/Metal.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blueColor;
    
    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"im_RGB" withExtension:@"png"];
    CIImage* inputImage = [CIImage imageWithContentsOfURL:imageURL];
    
    assert(inputImage != nil);
    
    size_t bytesPerImageRow = 512 * 3 * 4;
    size_t bytesPerImageTotal = bytesPerImageRow * 512;
    
    uint8_t* rgbaBytes = new uint8_t[512*512*3*4];
    
    CIContext* ciContext = [[CIContext alloc] init];
    [ciContext render:inputImage
             toBitmap:rgbaBytes
             rowBytes:bytesPerImageRow
               bounds:CGRectMake(0, 0, 512*3, 512)
               format:kCIFormatRGBA8
           colorSpace:inputImage.colorSpace];
    
    // check if R,G,B colors are correct in the top-most row
    ptrdiff_t r_tex_mid = 256*4;
    ptrdiff_t g_tex_mid = (512+256)*4;
    ptrdiff_t b_tex_mid = (512+512+256)*4;
    assert(rgbaBytes[r_tex_mid] == 255); assert(rgbaBytes[r_tex_mid+1] == 0);
    assert(rgbaBytes[g_tex_mid] == 0); assert(rgbaBytes[g_tex_mid+1] == 255);
    assert(rgbaBytes[b_tex_mid] == 0); assert(rgbaBytes[b_tex_mid+2] == 255);
    
    MTLTextureDescriptor* descriptor = [self createTextureDescriptor:512*3 height:512];
    
    id<MTLDevice> metalDevice = MTLCreateSystemDefaultDevice();
    id<MTLTexture> metalTexture = [metalDevice newTextureWithDescriptor:descriptor];
    assert(metalTexture != nil);
    
    id<MTLBuffer> metalBuffer = [metalDevice newBufferWithBytes:rgbaBytes
                                                         length:bytesPerImageRow*512
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    assert(metalBuffer != nil);
    
    id<MTLCommandQueue> commandQueue = [metalDevice newCommandQueue];
    assert(commandQueue != nil);
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    assert(blitEncoder != nil);
    
    [blitEncoder copyFromBuffer:metalBuffer
                   sourceOffset:0
              sourceBytesPerRow:bytesPerImageRow
            sourceBytesPerImage:bytesPerImageTotal
                     sourceSize:MTLSizeMake(512*3, 512, 1)
                      toTexture:metalTexture
               destinationSlice:0
               destinationLevel:0
              destinationOrigin:MTLOriginMake(0, 0, 0)
                        options:MTLBlitOptionNone];
    
    [blitEncoder endEncoding];
    [commandBuffer commit];
    
    delete [] rgbaBytes;
}

- (MTLTextureDescriptor*)createTextureDescriptor:(int)width height:(int)height
{
    MTLTextureUsage usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
    
    MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
    descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    descriptor.width = width;
    descriptor.height = height;
    descriptor.textureType = MTLTextureType2D;
    descriptor.usage = usage;
    descriptor.arrayLength = 1;
    
    return descriptor;
}

@end
