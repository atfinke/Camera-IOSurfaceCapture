//
//  Capturer.m
//  Camera+IOSurfaceCapture
//
//  Created by Andrew Finke on 2/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

#import "Capturer.h"

@interface UIWindow (Private)
- (IOSurfaceRef)createIOSurface;
@end

CGImageRef UICreateCGImageFromIOSurface(IOSurfaceRef ioSurface);

@implementation Capturer

+ (CGImageRef)captureFrame:(UIWindow *)window {
    CVReturn status = kCVReturnSuccess;
    CVPixelBufferRef pixelBuffer = NULL;

    IOSurfaceRef surface = [window createIOSurface];

    NSDictionary *pixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    status = CVPixelBufferCreateWithIOSurface(NULL, surface, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &pixelBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer);

    CGImageRef ref = UICreateCGImageFromIOSurface(surface);
    CFRelease(surface);

    CVPixelBufferRelease(pixelBuffer);
    return ref;
}

@end
