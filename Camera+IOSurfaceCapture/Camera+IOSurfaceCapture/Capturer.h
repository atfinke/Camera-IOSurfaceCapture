//
//  Capturer.h
//  Camera+IOSurfaceCapture
//
//  Created by Andrew Finke on 2/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

@import UIKit;

@interface Capturer : NSObject

+ (CGImageRef)captureFrame:(UIWindow *)window;

@end
