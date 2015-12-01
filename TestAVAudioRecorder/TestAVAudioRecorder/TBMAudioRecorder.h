//
//  TBMAudioRecorder.h
//  TestAVAudioRecorder
//
//  Created by alby on 15/7/8.
//  Copyright (c) 2015年 alby. All rights reserved.
//

@import Foundation;

@interface TBMAudioRecorder : NSObject

- (void)recordWithFileName:(NSString *)fileName;
- (void)recordWithFileName:(NSString *)fileName duration:(NSTimeInterval)duration;
- (void)pause;
- (void)resume;
- (void)stop;

@end
