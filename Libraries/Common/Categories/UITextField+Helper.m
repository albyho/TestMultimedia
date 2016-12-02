//
//  UITextField+Helper.m
//  ProjectLibrary
//
//  Created by alby on 15/3/13.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "UITextField+Helper.h"

@implementation UITextField (Helper)

- (void)setPlaceHolderColor:(UIColor *)color {
    [self setValue:color forKeyPath:@"_placeholderLabel.textColor"];
}

@end
