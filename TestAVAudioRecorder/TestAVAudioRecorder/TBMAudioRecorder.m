//
//  TBMAudioRecorder.m
//  TestAVAudioRecorder
//
//  Created by alby on 15/7/8.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "TBMAudioRecorder.h"
@import AVFoundation;

@interface TBMAudioRecorder ()<AVAudioRecorderDelegate>

@property (nonatomic) AVAudioRecorder     *audioRecorder;

@end

@implementation TBMAudioRecorder

- (void)dealloc {
    [self removeObservers];
}

- (void)recordWithFileName:(NSString *)fileName {
    NSLog(@"%s", __FUNCTION__);
    [self recordWithFileName:fileName duration:-1];
}

- (void)recordWithFileName:(NSString *)fileName duration:(NSTimeInterval)duration {
    NSLog(@"%s", __FUNCTION__);
    if(![self setupAudioSession]) {
        return;
    }
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName]];
    NSLog(@"%s url: %@", __FUNCTION__, url);
    const Float32 sampleRate = 44100.;
    //const Float32 bitRate = 128000.;
    NSDictionary *recordSettings = [self recordSettingsForLinearPCMWithSampleRate:sampleRate];
    //NSDictionary *recordSettings = [self recordSettingsForMPEG4AACWithSampleRate:sampleRate bitRate:bitRate];
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
    self.audioRecorder.delegate = self;

    // 准备录制
    //*
    if (![self.audioRecorder prepareToRecord]) {
        NSLog(@"%s Error: prepareToRecord", __FUNCTION__);
        [self restoreAudioSession];
        return;
    }
    //*/

    if(duration > 0) {
        if(![self.audioRecorder recordForDuration:duration]) {
            [self restoreAudioSession];
            NSLog(@"%s Error: recordForDuration", __FUNCTION__);
        }
    } else {
        if(![self.audioRecorder record]) {
            [self restoreAudioSession];
            NSLog(@"%s Error: record", __FUNCTION__);
        }
    }
}

- (void)pause {
    NSLog(@"%s", __FUNCTION__);
    [self.audioRecorder pause];
}

- (void)resume {
    NSLog(@"%s", __FUNCTION__);
    [self.audioRecorder record];
}

- (void)stop {
    NSLog(@"%s", __FUNCTION__);
    [self.audioRecorder stop];
}

- (NSDictionary *)recordSettingsForLinearPCMWithSampleRate:(Float32)sampleRate {
    return [self recordSettingsWithAudioFormatID:kAudioFormatLinearPCM sampleRate:sampleRate bitRate:0.];
}

- (NSDictionary *)recordSettingsForMPEG4AACWithSampleRate:(Float32)sampleRate
                                                  bitRate:(Float32)bitRate {
    return [self recordSettingsWithAudioFormatID:kAudioFormatMPEG4AAC sampleRate:sampleRate bitRate:bitRate];
}

- (NSDictionary *)recordSettingsWithAudioFormatID:(AudioFormatID)audioFormatID
                                       sampleRate:(Float32)sampleRate
                                          bitRate:(Float32)bitRate {
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [recordSettings setObject:@(audioFormatID) forKey: AVFormatIDKey];
    [recordSettings setObject:@(sampleRate) forKey: AVSampleRateKey];
    [recordSettings setObject:@1 forKey:AVNumberOfChannelsKey];
    
    if(audioFormatID == kAudioFormatLinearPCM) {
        [recordSettings setObject:@16 forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:@(NO) forKey:AVLinearPCMIsBigEndianKey];
        [recordSettings setObject:@(NO) forKey:AVLinearPCMIsFloatKey];
    } else {
        [recordSettings setObject:@(bitRate) forKey:AVEncoderBitRateKey];
        [recordSettings setObject:@(AVAudioQualityHigh) forKey: AVEncoderAudioQualityKey];
    }
    
    return recordSettings;
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
    if(![audioSession setCategory:AVAudioSessionCategoryRecord error:&error]) {
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
