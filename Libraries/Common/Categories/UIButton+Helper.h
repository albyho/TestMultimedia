//
//  UIButton+Helper.h
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIButton+WebCache.h"

@interface UIButton (Helper)

- (void)setEnlargeEdge:(CGFloat)value;
- (void)setEnlargeEdgeWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left;
- (void)centerImageAndTitle:(float)space;
- (void)centerImageAndTitle;

// url需以http或https开头
- (void)sd_setImageWithURLEx:(NSString *)url placeholderImage:(NSString *)placeholderImage;
- (void)sd_setImageWithURLEx:(NSString *)url completed:(SDWebImageCompletionBlock)completedBlock;
- (void)sd_setImageWithURLEx:(NSString *)url placeholderImage:(NSString *)placeholderImage completed:(SDWebImageCompletionBlock)completedBlock;

@end
