//
//  UITableViewCell+Helper.h
//  qsx
//
//  Created by alby on 15/8/19.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (Helper)

- (void)setSeparatorInsetWithUIEdgeInsets:(UIEdgeInsets)separatorInset;

@end

/*
在iOS7中，UITableViewCell左侧会有默认15像素的空白。这时候，设置setSeparatorInset:UIEdgeInsetsZero 能将空白去掉。

但是在iOS8中，设置setSeparatorInset:UIEdgeInsetsZero 已经不起作用了。下面是解决办法

首先在viewDidLoad方法加入以下代码：

if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
    
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
}

if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
    
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    
}

然后在UITableView的代理方法中加入以下代码
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath

{
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        
        [cell setSeparatorInset:UIEdgeInsetsZero];
        
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        
        [cell setLayoutMargins:UIEdgeInsetsZero];
        
    }
    
}

*/