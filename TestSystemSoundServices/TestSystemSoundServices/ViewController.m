//
//  ViewController.m
//  TestSystemSoundServices
//
//  Created by alby on 15/11/21.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "ViewController.h"
#import "TBMSoundEffect.h"

@interface ViewController ()

@property TBMSoundEffect *soundEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.soundEffect = [[TBMSoundEffect alloc] initWithVibrate];
    //self.soundEffect = [[TBMSoundEffect alloc] initWithFileName:@"Sound" withExtension:@"caf" type:TBMSoundEffectTypeAlertSound];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.soundEffect play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
