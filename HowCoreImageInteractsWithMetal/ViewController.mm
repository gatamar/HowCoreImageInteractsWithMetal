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
}
@end

@implementation ViewController

- (void)recreateMetalResourcesForWidth:(int)width andHeight:(int)height
{
    _metalTextureDescriptor = [self createTextureDescriptor:width height:height];
    
    _metalDevice = MTLCreateSystemDefaultDevice();
    
    _commandQueue = [_metalDevice newCommandQueue];
    assert(_commandQueue != nil);
}

- (void)loadCoreImageToMetalApproach2:(CIImage*)inputImage
{
    [self recreateMetalResourcesForWidth:512 andHeight:512];
    
    for ( int c=0; c<3; ++c )
    {
        @autoreleasepool
        {
            id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
            assert(commandBuffer != nil);
            commandBuffer.label = @"MySuperCommandBuffer";
            
            id<MTLTexture> metalTexture = [_metalDevice newTextureWithDescriptor:_metalTextureDescriptor];
            assert(metalTexture != nil);
            
            CIContext* ciContext = [[CIContext alloc] init];
            [ciContext render:inputImage
                 toMTLTexture:metalTexture
                commandBuffer:commandBuffer
                       bounds:CGRectMake(512*c, 0, 512, 512)
                   colorSpace:inputImage.colorSpace];
            
            [commandBuffer commit];
            
            NSLog(@"loadCoreImageToMetalApproach2: column rendered");
        }
    }
    
    abort();
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blueColor;
    
    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"im_RGB" withExtension:@"png"];
    CIImage* inputImage = [CIImage imageWithContentsOfURL:imageURL];
    assert(inputImage != nil);
    
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
