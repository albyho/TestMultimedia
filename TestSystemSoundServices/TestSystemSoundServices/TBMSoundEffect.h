//
//  TBMSoundEffect.h
//  Project
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, TBMSoundEffectType) {
    TBMSoundEffectTypeSystemSound,
    TBMSoundEffectTypeAlertSound,
    TBMSoundEffectTypeVibrateOnly
};

NS_ASSUME_NONNULL_BEGIN

@interface TBMSoundEffect : NSObject

@property (nonatomic, assign)   TBMSoundEffectType type;

- (instancetype)initWithVibrate;
- (nullable instancetype)initWithFileName:(NSString *)name withExtension:(nullable NSString *)ext type:(TBMSoundEffectType)type bundle:(nullable NSBundle *)nibBundleOrNil;
- (nullable instancetype)initWithFileName:(NSString *)name withExtension:(nullable NSString *)ext type:(TBMSoundEffectType)type;
- (void)play;

@end

NS_ASSUME_NONNULL_END
