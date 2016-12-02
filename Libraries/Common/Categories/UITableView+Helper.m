//
//  UITableView+Help.m
//  Pray
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "UITableView+Helper.h"

@implementation UITableView (Helper)

- (void)setExtraCellLineHidden:(BOOL)scrollEnabled
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    [self setTableFooterView:view];
    [self setScrollEnabled:scrollEnabled];
}

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
