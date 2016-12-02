//
//  UIViewController+Show.m
//  eliu
//
//  Created by tanghongping on 15/2/10.
//  Copyright (c) 2015年 THP. All rights reserved.
//

#import "UIViewController+Show.h"
#import "ProjectUtils.h"

@implementation UIViewController (Show)
@dynamic popGestureEnabled;

- (void)showViewController:(UIViewController*)viewController
{
    if (IsiOS8 || IsAfteriOS8) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self presentViewController:viewController animated:YES completion:nil];
        }];
    }else{
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)setPopGestureEnabled:(BOOL)popGestureEnabled
{
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = popGestureEnabled;
    }
}

@end
