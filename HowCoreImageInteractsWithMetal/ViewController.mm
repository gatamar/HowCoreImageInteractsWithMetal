//
//  ViewController.m
//  HowCoreImageInteractsWithMetal
//
//  Created by Olha Pavliuk on 27.10.2020.
//  Copyright © 2020 test. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blueColor;
    
    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"im_RGB" withExtension:@"png"];
    CIImage* inputImage = [CIImage imageWithContentsOfURL:imageURL];
    
    assert(inputImage != nil);
    
    ptrdiff_t bytesPerImageRow = 512 * 3 * 4;
    
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
    
    delete [] rgbaBytes;
}


@end
