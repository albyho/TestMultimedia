//
//  ViewController.m
//  TestMPMusicPlayerController
//
//  Created by alby on 15/11/25.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "ViewController.h"
#import "TBMMusicPlayer.h"
@import MediaPlayer;

@interface ViewController ()<MPMediaPickerControllerDelegate, TBMMusicPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;  // 不使用，仅为了界面布局，实际项目不要这样做
@property (nonatomic)       MPVolumeView *volumeView;         // 控制音量的view
@property (nonatomic)       UISlider *volumeViewSlider;       // 控制音量。暂未使用，如果要自定义音量控制UI，可通过操作其value属性进行音量设置

@property (nonatomic)   TBMMusicPlayer *musicPlayer;
@property (nonatomic)   float volume;
@property (nonatomic)   MPMediaItemCollection *mediaItemCollection;
@end

@implementation ViewController

- (void)dealloc {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.volumeView.frame = self.volumeSlider.frame;
    [self.view addSubview:self.volumeView];
    self.volumeSlider.hidden = YES;

    self.musicPlayer = [[TBMMusicPlayer alloc] initWithMusicPlayerController:MPMusicPlayerController.systemMusicPlayer];
    //self.musicPlayer = [[TBMMusicPlayer alloc] initWithMusicPlayerController:MPMusicPlayerController.applicationMusicPlayer];
    self.musicPlayer.delegate = self;
    
    self.pauseButton.enabled = NO;
    self.stopButton.enabled = NO;
}

#pragma mark - Actions
- (IBAction)actionPlay:(UIButton *)sender {
    MPMediaPickerController * mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    if(mediaPicker != nil) {
        NSLog(@"Successfully instantiated a media picker");
        mediaPicker.delegate = self;
        mediaPicker.allowsPickingMultipleItems = YES;
        mediaPicker.prompt = @"请选择要播放的歌曲";
        [self presentViewController:mediaPicker animated:YES completion:nil];
    } else {
        NSLog(@"Could not instantiate a media picker");
    }
}

- (IBAction)actionPause:(UIButton *)sender {
    if(!sender.isSelected) {
        [self.musicPlayer pause];
    } else {
        [self.musicPlayer resume];
    }
}

- (IBAction)actionStop:(UIButton *)sender {
    [self.musicPlayer stop];
    self.pauseButton.selected = NO;
}

#pragma mark - MPMediaPickerControllerDelegate
-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    NSLog(@"Media Picker returned");
    NSLog(@"Count: %lu MediaTypes: %@", (unsigned long)mediaItemCollection.count, [self stringWithMediaType:mediaItemCollection.mediaTypes]);
    self.mediaItemCollection = mediaItemCollection;
    
#ifdef LOG
    NSMutableString *log = [NSMutableString string];
    for (MPMediaItem *mediaItem in mediaItemCollection.items) {
        // 也可使用valueForProperty获取属性值，这里采用显示的属性访问以方便查看各种属性的类型。
        [log appendString:@"\n----------\n"];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyPersistentID,    (unsigned long)mediaItem.persistentID];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyMediaType,       [self stringWithMediaType:mediaItem.mediaType]];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyTitle,           mediaItem.title];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyAlbumTitle,      mediaItem.albumTitle];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyAlbumPersistentID, (unsigned long)mediaItem.albumPersistentID];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyArtist,          mediaItem.artist];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyArtistPersistentID, (unsigned long)mediaItem.artistPersistentID];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyAlbumArtist,     mediaItem.albumArtist];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyAlbumArtistPersistentID, (unsigned long)mediaItem.albumArtistPersistentID];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyGenre,           mediaItem.genre];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyGenrePersistentID, (unsigned long)mediaItem.genrePersistentID];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyComposer,        mediaItem.composer];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyComposerPersistentID, (unsigned long)mediaItem.composerPersistentID];
        [log appendFormat:@"%@:%f\n",   MPMediaItemPropertyPlaybackDuration, mediaItem.playbackDuration];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyAlbumTrackNumber, (unsigned long)mediaItem.albumTrackNumber];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyAlbumTrackCount, (unsigned long)mediaItem.albumTrackCount];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyDiscNumber,      mediaItem.discNumber];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyDiscCount,       mediaItem.discCount];
        if(mediaItem.artwork) {
            [log appendFormat:@"%@:[Bounds:%@ ImageCropRect:%@]\n",   MPMediaItemPropertyArtwork, NSStringFromCGRect(mediaItem.artwork.bounds), NSStringFromCGRect(mediaItem.artwork.imageCropRect)];
        }
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyLyrics,          mediaItem.lyrics];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyIsCompilation,   mediaItem.compilation ? @"YES" : @" NO"];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyReleaseDate,     mediaItem.releaseDate];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyBeatsPerMinute,  mediaItem.beatsPerMinute];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyComments,        mediaItem.comments];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyAssetURL,        mediaItem.assetURL];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyIsCloudItem,     mediaItem.cloudItem ? @"YES" : @" NO"];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyHasProtectedAsset, mediaItem.protectedAsset ? @"YES" : @" NO"];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyPodcastTitle,    mediaItem.podcastTitle];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyPodcastPersistentID, (unsigned long)mediaItem.podcastPersistentID];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyPlayCount,       mediaItem.playCount];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertySkipCount,       mediaItem.skipCount];
        [log appendFormat:@"%@:%lu\n",  MPMediaItemPropertyRating,          mediaItem.rating];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyLastPlayedDate,  mediaItem.lastPlayedDate];
        [log appendFormat:@"%@:%@\n",   MPMediaItemPropertyUserGrouping,    mediaItem.userGrouping];
        [log appendFormat:@"%@:%f\n",   MPMediaItemPropertyBookmarkTime,    mediaItem.bookmarkTime];
    }
    NSLog(@"%@", log);
#endif
    
    [self.musicPlayer playWithItemCollection:mediaItemCollection];
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    NSLog(@"Media Picker was cancelled");
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TBMMusicPlayerDelegate
- (void)tbmMusicPlayer:(TBMMusicPlayer *)tbmMusicPlayer playbackStateDidChange:(MPMusicPlaybackState)state {
    switch (state) {
        case MPMusicPlaybackStateStopped:
        {
            self.pauseButton.enabled = NO;
            self.stopButton.enabled = NO;
        }
            break;
        case MPMusicPlaybackStatePlaying:
        {
            self.pauseButton.enabled = YES;
            self.pauseButton.selected = NO;
            self.stopButton.enabled = YES;
        }
            break;
        case MPMusicPlaybackStatePaused:
        {
            self.pauseButton.selected = YES;
        }
            break;
        default:
            break;
    }
}

- (void)tbmMusicPlayer:(TBMMusicPlayer *)tbmMusicPlayer nowPlayingItemDidChange:(MPMediaEntityPersistentID)persistentID indexOfNowPlayingItem:(NSUInteger)indexOfNowPlayingItem {

}

- (void)tbmMusicPlayerVolumeDidChange:(TBMMusicPlayer *)tbmMusicPlayer {

}

#pragma mark - Properties
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                _volumeViewSlider = (UISlider *)view;
                break;
            }
        }
    }
    return _volumeView;
}

#pragma mark - Utils
- (NSString *)stringWithMediaType:(MPMediaType)mediaType {
    switch (mediaType) {
        case MPMediaTypeMusic:
            return @"MPMediaTypeMusic";
        case MPMediaTypePodcast:
            return @"MPMediaTypePodcast";
        case MPMediaTypeAudioBook:
            return @"MPMediaTypeAudioBook";
        case MPMediaTypeAudioITunesU:
            return @"MPMediaTypeAudioITunesU";
        case MPMediaTypeAnyAudio:
            return @"MPMediaTypeAnyAudio";
        case MPMediaTypeMovie:
            return @"MPMediaTypeMovie";
        case MPMediaTypeTVShow:
            return @"MPMediaTypeTVShow";
        case MPMediaTypeVideoPodcast:
            return @"MPMediaTypeVideoPodcast";
        case MPMediaTypeMusicVideo:
            return @"MPMediaTypeMusicVideo";
        case MPMediaTypeVideoITunesU:
            return @"MPMediaTypeVideoITunesU";
        case MPMediaTypeHomeVideo:
            return @"MPMediaTypeHomeVideo";
        case MPMediaTypeAnyVideo:
            return @"MPMediaTypeAnyVideo";
        case MPMediaTypeAny:
            return @"MPMediaTypeAny";
    }
}

@end
