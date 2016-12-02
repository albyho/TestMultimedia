//
//  UIImage+Helper.h
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Helper)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)pointWithColor:(UIColor *)color;

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)scaleToHeight:(CGFloat)height;
- (UIImage *)scaleToWidth:(CGFloat)width;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
//- (UIImage *)imageWithWaterMask:(UIImage*)mask inRect:(CGRect)rect;
- (UIImage *)imageWithWaterMask:(UIImage *)mask;
- (UIImage *)fixOrientation;

@end
