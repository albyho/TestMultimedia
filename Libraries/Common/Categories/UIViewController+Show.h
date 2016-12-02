//
//  UIViewController+Show.h
//  eliu
//
//  Created by tanghongping on 15/2/10.
//  Copyright (c) 2015年 THP. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Show)
@property (nonatomic) BOOL popGestureEnabled; // 返回手势可用性

// 显示界面(用于适配iOS8)
- (void)showViewController:(UIViewController*)viewController;

@end
