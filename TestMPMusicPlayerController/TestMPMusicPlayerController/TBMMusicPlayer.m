//
//  TBMMusicPlayer.m
//  TestMPMusicPlayerController
//
//  Created by alby on 16/8/1.
//  Copyright © 2016年 alby. All rights reserved.
//

#import "TBMMusicPlayer.h"
@import MediaPlayer;

@interface TBMMusicPlayer ()

@property (nonatomic, readwrite)     MPMusicPlayerController *musicPlayerController;

@end

@implementation TBMMusicPlayer

- (void)dealloc {
    [self removeObservers];
}

- (instancetype)initWithMusicPlayerController:(MPMusicPlayerController *)musicPlayerController {
    self = [super init];
    if(self) {
        _musicPlayerController = musicPlayerController;
        _musicPlayerController.repeatMode = MPMusicRepeatModeDefault;
        _musicPlayerController.shuffleMode = MPMusicRepeatModeDefault;
        [_musicPlayerController beginGeneratingPlaybackNotifications];
        [self addObservers];
    }
    return self;
}

- (void)playWithMediaItem:(MPMediaItem *)mediaItem {
    [self.musicPlayerController stop];
    
    [self.musicPlayerController setNowPlayingItem:mediaItem];
    [self.musicPlayerController play]; //  测试：是否不需要调用play方法
}

- (void)playWithItemCollection:(MPMediaItemCollection *)itemCollection {
    [self.musicPlayerController stop];
    
    [self.musicPlayerController setQueueWithItemCollection:itemCollection];
    [self.musicPlayerController play];
}

#pragma mark - Notifications
- (void)addObservers {
    // init方法中使用，不使用属性
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(musicPlaybackStateDidChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:_musicPlayerController];
    [nc addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:_musicPlayerController];
    [nc addObserver:self selector:@selector(volumeDidChange:) name:MPMusicPlayerControllerVolumeDidChangeNotification object:_musicPlayerController];
    ;
}

- (void)removeObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.musicPlayerController];
    [nc removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.musicPlayerController];
    [nc removeObserver:self name:MPMusicPlayerControllerVolumeDidChangeNotification object:self.musicPlayerController];
}

- (void)musicPlaybackStateDidChange:(NSNotification *)notification {
    NSNumber *stateAsObject = [notification.userInfo objectForKey:@"MPMusicPlayerControllerPlaybackStateKey"];
    NSInteger state = [stateAsObject integerValue];
    NSLog(@"Player State Changed: %@", [self stringWithMPMusicPlaybackState:state]);
    if ([self.delegate respondsToSelector:@selector(tbmMusicPlayer:playbackStateDidChange:)]) {
        [self.delegate tbmMusicPlayer:self playbackStateDidChange:state];
    }
}

- (void)nowPlayingItemDidChange:(NSNotification *)notification {
    NSNumber *persistentIDAsObject = [notification.userInfo objectForKey:@"MPMusicPlayerControllerNowPlayingItemPersistentIDKey"];
    NSLog(@"Playing Item did Change: %@ IndexOfNowPlayingItem: %lu", persistentIDAsObject, (unsigned long)self.musicPlayerController.indexOfNowPlayingItem);
    if ([self.delegate respondsToSelector:@selector(tbmMusicPlayer:nowPlayingItemDidChange:indexOfNowPlayingItem:)]) {
        [self.delegate tbmMusicPlayer:self
              nowPlayingItemDidChange:(MPMediaEntityPersistentID)[persistentIDAsObject unsignedLongLongValue]
                indexOfNowPlayingItem:self.musicPlayerController.indexOfNowPlayingItem
         ];
    }
}

- (void)volumeDidChange:(NSNotification *)notification {
    NSLog(@"Volume Did Change");
}

#pragma mark - Utils
           
- (NSString *)stringWithMPMusicPlaybackState:(MPMusicPlaybackState)state {
    switch (state) {
        case MPMusicPlaybackStateStopped:
            return @"MPMusicPlaybackStateStopped";
        case MPMusicPlaybackStatePlaying:
            return @"MPMusicPlaybackStatePlaying";
        case MPMusicPlaybackStatePaused:
            return @"MPMusicPlaybackStatePaused";
        case MPMusicPlaybackStateInterrupted:
            return @"MPMusicPlaybackStateInterrupted";
        case MPMusicPlaybackStateSeekingForward:
            return @"MPMusicPlaybackStateSeekingForward";
        case MPMusicPlaybackStateSeekingBackward:
            return @"MPMusicPlaybackStateSeekingBackward";
    }
}

@end
