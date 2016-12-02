//
//  UITableView+Helper.h
//
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UITableView (Helper)

- (void)setExtraCellLineHidden:(BOOL)scrollEnabled;

- (void)setSeparatorInsetWithUIEdgeInsets:(UIEdgeInsets)separatorInset;

@end