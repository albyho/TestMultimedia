//
//  MPMoviePlayerViewController+Rotation.m
//  TestVideoRecorder
//
//  Created by alby on 15/3/23.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "MPMoviePlayerViewController+Rotation.h"

@implementation MPMoviePlayerViewController (Rotation)

- (void)rotateVideoViewWithDegrees:(NSInteger)degrees
{
    if(degrees == 0 || degrees == 360) return;
    if(degrees < 0) degrees = (degrees % 360) + 360;
    if(degrees > 360) degrees = degrees % 360;
    
    // Tag为1002的在iOS8中为一个MPVideoView，不排除苹果以后更改的可能性。
    UIView *videoView = [self.view viewWithTag:1002];
    if ([videoView isKindOfClass:NSClassFromString(@"MPVideoView")]) {
        videoView.transform = CGAffineTransformMakeRotation(M_PI * degrees / 180.0);
        videoView.frame = self.view.bounds;
    }
}

@end
