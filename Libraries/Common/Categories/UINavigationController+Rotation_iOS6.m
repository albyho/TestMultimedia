//
//  UINavigationController+Rotation_iOS6.m
//  ProjectLibrary
//
//  Created by ho alby on 13-10-15.
//  Copyright (c) 2013年 ho alby. All rights reserved.
//

#import "UINavigationController+Rotation_iOS6.h"

@implementation UINavigationController (Rotation_iOS6)

-(BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end
