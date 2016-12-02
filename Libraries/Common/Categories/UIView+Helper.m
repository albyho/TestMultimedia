//
//  UIView+position.m
//
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "UIView+Position.h"

@implementation UIView (Helper)

- (void)setCircle
{
    [self setCornerRadius:self.frame.size.width/2.];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    CALayer *layer=[self layer];
    layer.masksToBounds = YES;
    layer.cornerRadius = cornerRadius;
    //layer.borderColor = UIColor.blackColor.CGColor;
    //layer.borderWidth = 1;
}

@end