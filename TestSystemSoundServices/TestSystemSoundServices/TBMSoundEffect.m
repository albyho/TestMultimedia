//
//  TBMSoundEffect.m
//  Project
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "TBMSoundEffect.h"
@import AudioToolbox;

static void SoundFinished(SystemSoundID ssID, void* clientData) {
    NSLog(@"Finished!");
}

@interface TBMSoundEffect ()

@property (nonatomic)   SystemSoundID soundID;

@end

@implementation TBMSoundEffect

- (instancetype)initWithVibrate {
    self = [super init];
    if (self) {
        _type = TBMSoundEffectTypeVibrateOnly;
        _soundID = kSystemSoundID_Vibrate;
    }
    return self;
}

- (nullable instancetype)initWithFileName:(nonnull NSString *)name withExtension:(nullable NSString *)ext type:(TBMSoundEffectType)type bundle:(nullable NSBundle *)nibBundleOrNil {
    if(_type == TBMSoundEffectTypeVibrateOnly) {
        NSLog(@"%s Failed to create instance: type must not be TBMSoundEffectTypeVibrateOnly", __FUNCTION__);
        return nil;
    }
    self = [super init];
    if (self) {
        _type = type;
        NSBundle *currentBundle = nibBundleOrNil ?: [NSBundle mainBundle];
        NSURL *fileURL = [currentBundle URLForResource:name withExtension:ext];
        if (fileURL != nil) {
            SystemSoundID soundID;
            OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &soundID);
            
            if (error == kAudioServicesNoError) {
                _soundID = soundID;
            } else {
                NSLog(@"%s Failed to create instance", __FUNCTION__);
                self = nil;
            }
            AudioServicesAddSystemSoundCompletion(_soundID, NULL, NULL, &SoundFinished, NULL);
        }
    }
    return self;
}

- (nullable instancetype)initWithFileName:(nonnull NSString *)name withExtension:(nullable NSString *)ext type:(TBMSoundEffectType)type {
    return [self initWithFileName:name withExtension:ext type:type bundle:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    AudioServicesRemoveSystemSoundCompletion(self.soundID);
    AudioServicesDisposeSystemSoundID(self.soundID);
}

- (void)play {
    switch (self.type) {
        case TBMSoundEffectTypeSystemSound:
            // iOS9及以后使用AudioServicesPlaySystemSoundWithCompletion
            AudioServicesPlaySystemSound(self.soundID);
            break;
        case TBMSoundEffectTypeAlertSound:
            // iOS9及以后使用AudioServicesPlayAlertSoundWithCompletion
            AudioServicesPlayAlertSound(self.soundID);
            break;
        case TBMSoundEffectTypeVibrateOnly:
            // iOS9及以后使用AudioServicesPlaySystemSoundWithCompletion
            // 这里使用AudioServicesPlaySystemSound和AudioServicesPlayAlertSound都可以
            AudioServicesPlaySystemSound(self.soundID);
            break;
    }
}

@end
