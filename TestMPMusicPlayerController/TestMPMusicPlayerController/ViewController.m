//
//  ViewController.m
//  TestMPMusicPlayerController
//
//  Created by alby on 15/11/25.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;

@interface ViewController ()

@property (nonatomic)   MPMusicPlayerController *musicPlayerController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.musicPlayerController = MPMusicPlayerController.applicationMusicPlayer;
}

#pragma Actions
- (IBAction)actionPlay:(id)sender {

}

- (IBAction)actionPause:(id)sender {

}

- (IBAction)actionStop:(id)sender {

}

#pragma Notifications
- (void)addObservers {

}

- (void)removeObservers {

}

@end
