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
    IOSurfaceRef surface = [window createIOSurface];
    CGImageRef ref = UICreateCGImageFromIOSurface(surface);
    CFRelease(surface);
    return ref;
}

@end
