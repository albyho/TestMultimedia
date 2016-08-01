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

NS_ASSUME_NONNULL_BEGIN

@interface TBMMusicPlayer : NSObject

@property (nonatomic, nullable)     MPMusicPlayerController *musicPlayerController;

- (void)playWithMediaItem:(MPMediaItem *)mediaItem;
- (void)playWithItemCollection:(MPMediaItemCollection *)itemCollection;
- (void)pause;
- (void)resume;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
