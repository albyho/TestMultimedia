//
//  TBMAudioPlayer.h
//  TestAVAudioRecorder
//
//  Created by alby on 15/11/18.
//  Copyright © 2015年 alby. All rights reserved.
//

@import Foundation;

@interface TBMAudioPlayer : NSObject

- (void)playWithFileName:(NSString *)fileName;
- (void)pause;
- (void)resume;
- (void)stop;

@end
