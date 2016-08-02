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
    }
    return self;
}

- (void)playWithMediaItem:(MPMediaItem *)mediaItem {
    [self stop];
    
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    [self addObservers];
    [self.musicPlayerController endGeneratingPlaybackNotifications];
    
    [self.musicPlayerController setNowPlayingItem:mediaItem];
    [self.musicPlayerController play];
}

- (void)playWithItemCollection:(MPMediaItemCollection *)itemCollection {
    [self stop];
    
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    [self addObservers];
    [self.musicPlayerController endGeneratingPlaybackNotifications];
    
    [self.musicPlayerController setQueueWithItemCollection:itemCollection];
    [self.musicPlayerController play];

}

- (void)pause {
    [self.musicPlayerController pause];
}

- (void)resume {
    [self.musicPlayerController play];
}

- (void)stop {
    [self removeObservers];
    [self.musicPlayerController stop];
}

#pragma mark - Notifications
- (void)addObservers {
    if(!self.musicPlayerController) return;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(musicPlayerStatedDidChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.musicPlayerController];
    [nc addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.musicPlayerController];
    [nc addObserver:self selector:@selector(volumeDidChange:) name:MPMusicPlayerControllerVolumeDidChangeNotification object:self.musicPlayerController];
    ;
}

- (void)removeObservers {
    if(!self.musicPlayerController) return;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.musicPlayerController];
    [nc removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.musicPlayerController];
    [nc removeObserver:self name:MPMusicPlayerControllerVolumeDidChangeNotification object:self.musicPlayerController];
}

-(void)musicPlayerStatedDidChange:(NSNotification *)notification {
    NSNumber *stateAsObject = [notification.userInfo objectForKey:@"MPMusicPlayerControllerPlaybackStateKey"];
    NSInteger state = [stateAsObject integerValue];
    NSLog(@"Player State Changed: %@", [self stringWithMPMusicPlaybackState:state]);
}

-(void)nowPlayingItemDidChange:(NSNotification *)notification {
    NSString * persistentID = [notification.userInfo objectForKey:@"MPMusicPlayerControllerNowPlayingItemPersistentIDKey"];
    NSLog(@"Playing Item did Change: %@", persistentID);
}

-(void)volumeDidChange:(NSNotification *)notification {
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
