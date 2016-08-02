//
//  TBMMusicPlayer.h
//  TestMPMusicPlayerController
//
//  Created by alby on 16/8/1.
//  Copyright © 2016年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class TBMMusicPlayer;

NS_ASSUME_NONNULL_BEGIN

@protocol TBMMusicPlayerDelegate <NSObject>

- (void)tbmMusicPlayer:(TBMMusicPlayer *)tbmMusicPlayer playbackStateDidChange:(MPMusicPlaybackState)state;
- (void)tbmMusicPlayer:(TBMMusicPlayer *)tbmMusicPlayer nowPlayingItemDidChange:(MPMediaEntityPersistentID)persistentID;
- (void)tbmMusicPlayerVolumeDidChange:(TBMMusicPlayer *)tbmMusicPlayer;

@end

@interface TBMMusicPlayer : NSObject

@property (nonatomic, weak, nullable)       id<TBMMusicPlayerDelegate> delegate;
@property (nonatomic, readonly)             MPMusicPlayerController *musicPlayerController;

- (instancetype)initWithMusicPlayerController:(MPMusicPlayerController *)musicPlayerController;

- (void)playWithMediaItem:(MPMediaItem *)mediaItem;
- (void)playWithItemCollection:(MPMediaItemCollection *)itemCollection;
- (void)pause;
- (void)resume;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
