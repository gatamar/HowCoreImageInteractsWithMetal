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
{
    MTLTextureDescriptor* _metalTextureDescriptor;
    id<MTLDevice> _metalDevice;
    id<MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
}
@end

@implementation ViewController

- (void)recreateMetalResourcesForWidth:(int)width andHeight:(int)height
{
    _metalTextureDescriptor = [self createTextureDescriptor:512*3 height:512];
    
    _metalDevice = MTLCreateSystemDefaultDevice();
    
    _commandQueue = [_metalDevice newCommandQueue];
    assert(_commandQueue != nil);
    
    _commandBuffer = [_commandQueue commandBuffer];
    assert(_commandBuffer != nil);
    _commandBuffer.label = @"MySuperCommandBuffer";
}

- (void)loadCoreImageToMetalApproach2:(CIImage*)inputImage
{
    [self recreateMetalResourcesForWidth:512*3 andHeight:512];
    
    id<MTLTexture> metalTexture = [_metalDevice newTextureWithDescriptor:_metalTextureDescriptor];
    assert(metalTexture != nil);
    
    CIContext* ciContext = [[CIContext alloc] init];
    [ciContext render:inputImage
         toMTLTexture:metalTexture
        commandBuffer:_commandBuffer
               bounds:CGRectMake(0, 0, 512*3, 512)
           colorSpace:inputImage.colorSpace];
    
    [_commandBuffer commit];
    
    abort();
}

- (void)loadCoreImageToMetalApproach1:(CIImage*)inputImage
{
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
    
    [self recreateMetalResourcesForWidth:512*3 andHeight:512];
    
    id<MTLTexture> metalTexture = [_metalDevice newTextureWithDescriptor:_metalTextureDescriptor];
    assert(metalTexture != nil);
    
    id<MTLBuffer> metalBuffer = [_metalDevice newBufferWithBytes:rgbaBytes
                                                          length:bytesPerImageRow*512
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    assert(metalBuffer != nil);
    
    id<MTLBlitCommandEncoder> _blitEncoder = [_commandBuffer blitCommandEncoder];
    assert(_blitEncoder != nil);
    
    [_blitEncoder copyFromBuffer:metalBuffer
                   sourceOffset:0
              sourceBytesPerRow:bytesPerImageRow
            sourceBytesPerImage:bytesPerImageTotal
                     sourceSize:MTLSizeMake(512*3, 512, 1)
                      toTexture:metalTexture
               destinationSlice:0
               destinationLevel:0
              destinationOrigin:MTLOriginMake(0, 0, 0)
                        options:MTLBlitOptionNone];
    
    [_blitEncoder endEncoding];
    [_commandBuffer commit];
    
    delete [] rgbaBytes;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blueColor;
    
    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"im_RGB" withExtension:@"png"];
    CIImage* inputImage = [CIImage imageWithContentsOfURL:imageURL];
    assert(inputImage != nil);
    
    //[self loadCoreImageToMetalApproach1:inputImage];
    [self loadCoreImageToMetalApproach2:inputImage];
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
