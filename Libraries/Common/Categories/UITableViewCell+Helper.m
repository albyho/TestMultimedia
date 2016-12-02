//
//  UITableViewCell+Helper.m
//  qsx
//
//  Created by alby on 15/8/19.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "UITableViewCell+Helper.h"

@implementation UITableViewCell (Helper)

- (void)setSeparatorInsetWithUIEdgeInsets:(UIEdgeInsets)separatorInset
{
    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        [self setSeparatorInset:separatorInset];
    }
    if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
        [self setLayoutMargins:separatorInset];
    }
}

@end
