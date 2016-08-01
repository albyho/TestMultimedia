//
//  TBMAudioPlayer.m
//  TestAVAudioRecorder
//
//  Created by alby on 15/11/18.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "TBMAudioPlayer.h"
@import AVFoundation;

@interface TBMAudioPlayer ()<AVAudioPlayerDelegate>

@property (nonatomic) AVAudioPlayer     *audioPlayer;

@end

@implementation TBMAudioPlayer

- (void)dealloc {
    [self removeObservers];
}

- (void)playWithFileName:(NSString *)fileName {
    if(![self setupAudioSession]) {
        return;
    }
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName]];
    NSLog(@"%s url: %@", __FUNCTION__, url);
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.delegate = self;
    
    // 音量
    self.audioPlayer.volume = 1.0;
    // 声源平移。想象一下在桌子上移动PC上常用的外置音响的效果。
    self.audioPlayer.pan = 0.0;
    // 播放速率
    self.audioPlayer.enableRate = YES;
    self.audioPlayer.rate = 1.0;
    // 循环次数。0标示播放1次循环0次共播放1次，1表示播放1次循环1次共播放2次，以此类推。负数将无限循环。
    self.audioPlayer.numberOfLoops = 0;
    // 从头开始播放
    self.audioPlayer.currentTime = 0.0;
    
    // 准备播放
    //*
    if (![self.audioPlayer prepareToPlay]) {
        NSLog(@"%s Error: prepareToPlay", __FUNCTION__);
        [self restoreAudioSession];
        return;
    }
    //*/
    NSLog(@"%s numberOfChannels: %lu", __FUNCTION__, (unsigned long)self.audioPlayer.numberOfChannels);
    NSLog(@"%s duration: %lf", __FUNCTION__, self.audioPlayer.duration);
    NSLog(@"%s settings: %@", __FUNCTION__, self.audioPlayer.settings);
    // 播放
    if(![self.audioPlayer play]) {
        [self restoreAudioSession];
        NSLog(@"%s Error: play", __FUNCTION__);
    }
}

- (void)pause {
    [self.audioPlayer pause];
}

- (void)resume {
    [self.audioPlayer play];
}

- (void)stop {
    [self.audioPlayer stop];
}


#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"%s flag: %d", __FUNCTION__, flag);
    [self restoreAudioSession];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    NSLog(@"%s Error: %@", __FUNCTION__, error);
    [self restoreAudioSession];
}

#pragma mark - Notifications
- (void)addObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // add interruption handler
    [nc addObserver:self
           selector:@selector(handleInterruption:)
               name:AVAudioSessionInterruptionNotification
             object:audioSession];
    
    // we don't do anything special in the route change notification
    [nc addObserver:self
           selector:@selector(handleRouteChange:)
               name:AVAudioSessionRouteChangeNotification
             object:audioSession];
}

- (void)removeObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [nc removeObserver:self name:AVAudioSessionInterruptionNotification object:audioSession];
    [nc removeObserver:self name:AVAudioSessionRouteChangeNotification object:audioSession];
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"%s flag: %d", __FUNCTION__, flag);
    [self restoreAudioSession];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"%s Error: %@", __FUNCTION__, error);
    [self restoreAudioSession];
}

#pragma mark - AudioSession
- (BOOL)setupAudioSession {
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if(![audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"%s Error: %@", __FUNCTION__, error);
        return NO;
    }
    [self addObservers];
    if(![audioSession setActive:YES error:&error]) {
        NSLog(@"%s Error: %@", __FUNCTION__, error);
        return NO;
    }
    return YES;
}

- (BOOL)restoreAudioSession {
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [self removeObservers];
    if(![audioSession setActive:NO error: &error]) {
        NSLog(@"%s Error: %@", __FUNCTION__, error);
        return NO;
    }
    return YES;
}

#pragma mark - Audio Session Interruption Notification
- (void)handleInterruption:(NSNotification *)notification {
    UInt8 interruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", interruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
	   
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
    }
    
    if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure we are again the active session
        if (![self setupAudioSession])
           return;
        
        [self resume];
    }
}

#pragma mark - Audio Session Route Change Notification
- (void)handleRouteChange:(NSNotification *)notification {
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@"     New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

@end
