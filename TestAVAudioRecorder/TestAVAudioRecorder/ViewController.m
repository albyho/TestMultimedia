//
//  ViewController.m
//  TestAVAudioRecorder
//
//  Created by alby on 15/7/6.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "ViewController.h"
#import "TBMAudioRecorder.h"
#import "TBMAudioPlayer.h"
@import Foundation;
@import AVKit;
@import AVFoundation;
@import MediaPlayer;

NSString * const FileName = @"audio.m4a";

@interface ViewController ()<AVAudioRecorderDelegate>

@property (nonatomic) TBMAudioRecorder     *audioRecorder;
@property (nonatomic) TBMAudioPlayer       *audioPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //*
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.frame = CGRectMake(20, 40, 280, 30);
    [volumeView setShowsVolumeSlider:YES];
    [volumeView setShowsRouteButton:NO];
    [volumeView sizeToFit];
    [self.view addSubview:volumeView];
    //*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionRecord:(id)sender {
    if (!self.audioRecorder) {
        self.audioRecorder = [[TBMAudioRecorder alloc] init];
    }
    [self.audioRecorder recordWithFileName:FileName];
}

- (IBAction)actionRecordPause:(id)sender {
    [self.audioRecorder pause];
}

- (IBAction)actionRecordResume:(id)sender {
    [self.audioRecorder resume];
}

- (IBAction)actionRecordstop:(id)sender {
    [self.audioRecorder stop];
}

- (IBAction)actionPlay:(id)sender {
    if (!self.audioPlayer) {
        self.audioPlayer = [[TBMAudioPlayer alloc] init];
    }
    [self.audioPlayer playWithFileName:FileName];
}

- (IBAction)actionPlayPause:(id)sender {
    [self.audioPlayer pause];
}

- (IBAction)actionPlayResume:(id)sender {
    [self.audioPlayer resume];
}

- (IBAction)actionPlaystop:(id)sender {
    [self.audioPlayer stop];
}


@end
