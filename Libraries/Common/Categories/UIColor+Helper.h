//
//  UIColor+Helper.h
//  ProjectLibrary
//
//  Created by alby on 14/9/23.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define RGB(r,g,b) RGBA(r,g,b,1.0f)
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:(CGFloat)a]

#define UIColorFromRGB(rgb) [UIColor colorWithRed:((CGFloat)((rgb & 0xFF0000) >> 16))/255.0 green:((CGFloat)((rgb & 0xFF00) >> 8))/255.0 blue:((CGFloat)(rgb & 0xFF))/255.0 alpha:1.0]
#define UIColorFromRGBA(rgb,a) [UIColor colorWithRed:((CGFloat)((rgb & 0xFF0000) >> 16))/255.0 green:((CGFloat)((rgb & 0xFF00) >> 8))/255.0 blue:((CGFloat)(rgb & 0xFF))/255.0 alpha:(CGFloat)a]

#define CLEARCOLOR [UIColor clearColor]

@interface UIColor (Helper)

// 支持格式：0x123abc 0X123ABC #123abc #123ABC 123abc 123ABC
+ (UIColor *)colorWithHexString:(NSString *)color;
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

@end

