//
//  CMMotionManager+Shared.h
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

@interface CMMotionManager (Shared)

// adds a method to CMMotionManager to hand out a shared instance

+ (CMMotionManager *)sharedMotionManager;

@end
