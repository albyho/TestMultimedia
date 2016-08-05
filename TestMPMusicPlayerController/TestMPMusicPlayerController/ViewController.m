//
//  ViewController.m
//  TestMPMusicPlayerController
//
//  Created by alby on 15/11/25.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;

@interface ViewController ()<MPMediaPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;  // 不使用，仅为了界面布局，实际项目不要这样做
@property (nonatomic)       MPVolumeView *volumeView;         // 控制音量的view
@property (nonatomic)       UISlider *volumeViewSlider;       // 控制音量。暂未使用，如果要自定义音量控制UI，可通过操作其value属性进行音量设置
@property (nonatomic)       float volume;                     // 当前音量。暂未使用，目的同volumeViewSlider

@property (weak, nonatomic) IBOutlet UITableView *playbackTableView;

@property (nonatomic)       MPMusicPlayerController *musicPlayerController;
@property (nonatomic)       MPMediaItemCollection *mediaItemCollection;

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

    self.musicPlayerController = MPMusicPlayerController.applicationMusicPlayer;
    self.musicPlayerController.repeatMode = MPMusicRepeatModeDefault;
    self.musicPlayerController.shuffleMode = MPMusicRepeatModeDefault;
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    [self addObservers];
    
    self.playButton.enabled = NO;
    self.pauseButton.enabled = NO;
    self.stopButton.enabled = NO;
    
    self.previousButton.enabled = NO;
    self.progressSlider.enabled = NO;
    self.nextButton.enabled = NO;
}

#pragma mark - Actions
- (IBAction)actionSelect:(UIButton *)sender {
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

- (IBAction)actionPlay:(UIButton *)sender {
    [self.musicPlayerController play];
    
    self.playButton.enabled = NO;
    self.pauseButton.enabled = YES;
    self.stopButton.enabled = YES;
}

- (IBAction)actionPause:(UIButton *)sender {
    [self.musicPlayerController pause];
    
    self.playButton.enabled = YES;
    self.pauseButton.enabled = NO;
    self.stopButton.enabled = YES;
}

- (IBAction)actionStop:(UIButton *)sender {
    [self.musicPlayerController stop];
    
    self.playButton.enabled = YES;
    self.pauseButton.enabled = NO;
    self.stopButton.enabled = NO;
}

- (IBAction)actionPrevious:(UIButton *)sender {
    [self.musicPlayerController skipToPreviousItem];
    
    // 确保暂停时能继续播放
    [self actionPlay:self.playButton];
}

- (IBAction)actionNext:(UIButton *)sender {
    [self.musicPlayerController skipToNextItem];
    
    // 确保暂停时能继续播放
    [self actionPlay:self.playButton];
}

#pragma mark - MPMediaPickerControllerDelegate
-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    NSLog(@"Media Picker returned");
    NSLog(@"Count: %lu MediaTypes: %@", (unsigned long)mediaItemCollection.count, [self stringWithMediaType:mediaItemCollection.mediaTypes]);
    self.mediaItemCollection = mediaItemCollection;
    [self.playbackTableView reloadData];
    
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
    
    [self.musicPlayerController setQueueWithItemCollection:mediaItemCollection];
    [self.musicPlayerController play];
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    NSLog(@"Media Picker was cancelled");
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.musicPlayerController setNowPlayingItem:[self.mediaItemCollection.items objectAtIndex:indexPath.row]];
    [self.musicPlayerController play]; // 再次调用play，确保播放pause或stop后能自动播放
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.mediaItemCollection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [self.mediaItemCollection.items objectAtIndex:indexPath.row].title;
    
    return cell;
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
    switch (state) {
        case MPMusicPlaybackStateStopped:
        {
            self.playButton.enabled = YES;
            self.pauseButton.enabled = NO;
            self.stopButton.enabled = NO;
        }
            break;
        case MPMusicPlaybackStatePlaying:
        {
            self.playButton.enabled = NO;
            self.pauseButton.enabled = YES;
            self.stopButton.enabled = YES;
        }
            break;
        case MPMusicPlaybackStatePaused:
            
        {
            self.playButton.enabled = YES;
            self.pauseButton.enabled = NO;
            self.stopButton.enabled = YES;
        }
            break;
        default:
            break;
    }

}

- (void)nowPlayingItemDidChange:(NSNotification *)notification {
    NSNumber *persistentIDAsObject = [notification.userInfo objectForKey:@"MPMusicPlayerControllerNowPlayingItemPersistentIDKey"];
    NSLog(@"Playing Item did Change: %@ IndexOfNowPlayingItem: %lu", persistentIDAsObject, (unsigned long)self.musicPlayerController.indexOfNowPlayingItem);
    
    // Previous如果没有上一首 或 Next如果没有下一首会停止播放，取消选择。
    [self.playbackTableView deselectRowAtIndexPath:self.playbackTableView.indexPathForSelectedRow animated:YES];
    
    self.previousButton.enabled = NO;
    self.nextButton.enabled = NO;

    if(self.musicPlayerController.indexOfNowPlayingItem >= self.mediaItemCollection.count) {
        // 可能self.musicPlayerController.indexOfNowPlayingItem NSNotFound
        return;
    }
    
    if(self.musicPlayerController.indexOfNowPlayingItem > 0) {
        // 有上一首
        self.previousButton.enabled = YES;
    }
    if(self.musicPlayerController.indexOfNowPlayingItem < self.mediaItemCollection.count - 1){
        // 有下一首
        self.nextButton.enabled = YES;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.musicPlayerController.indexOfNowPlayingItem inSection:0];
    [self.playbackTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

}

- (void)volumeDidChange:(NSNotification *)notification {
    NSLog(@"Volume Did Change");
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

- (void)setVolume:(float)volume {
    _volumeViewSlider.value = volume;
}

- (float)volume {
    return _volumeSlider.value;
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
