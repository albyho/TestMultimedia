//
//  ViewController.m
//  TestMP3ToPCM
//
//  Created by alby on 2016/11/29.
//  Copyright © 2016年 alby. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegAudioFileDecoder.h"
#import "FFmpegAACEncoder.h"
#import "FFmpegAACDecoder.h"
#import "AudioConverterAACDecoder.h"
#import "TBMDefines.h"
#import "FFmpegMP4Writer.h"

@interface ViewController ()

@property (nonatomic) FFmpegAudioFileDecoder *audioFileDecoder;
@property (nonatomic) FFmpegAACEncoder *aacEncoder;
@property (nonatomic) FFmpegAACDecoder *aacDecoder;

@property (nonatomic) AudioConverterAACDecoder *acAACDecoder;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)actionButton1:(id)sender {
    //*
    NSString *srcFilePath = [[NSBundle mainBundle] pathForResource:@"booty music 男女双声道混音" ofType:@"mp3"];
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音.pcm"];
    //*/
    
    /*
    NSString *srcFilePath = [[NSBundle mainBundle] pathForResource:@"IMG_4084" ofType:@"MOV"];
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"IMG_4084.pcm"];
    //*/
    
    /*
    NSString *srcFilePath = [[NSBundle mainBundle] pathForResource:@"ChuAiJiJi" ofType:@"m4a"];
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"ChuAiJiji.pcm"];
    //*/
    
    NSLog(@"%@", dstFilePath);
    
    self.audioFileDecoder = [[FFmpegAudioFileDecoder alloc] init];
    [self.audioFileDecoder decodeWithSourceFilePath:srcFilePath destinationFilePath:dstFilePath completionHandler:^{
        NSLog(@"%@", @"OK");
    } errorHandler:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (IBAction)actionButton2:(id)sender {
#define kWriteLen 1
    NSString *srcFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音.pcm"];
#ifdef kWriteLen
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音(含包长).aac"];
#else 
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音.aac"];
#endif
    NSLog(@"%@", dstFilePath);
    
    self.aacEncoder = [[FFmpegAACEncoder alloc] init];
    [self.aacEncoder startup:128 * 1000];
    
    FILE *srcFile = fopen([srcFilePath UTF8String], "rb");
    if(!srcFilePath) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }
    FILE *dstFile = fopen([dstFilePath UTF8String], "wb");
    if(!dstFile) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }
    
    size_t readed;
    int pcmBufferSize = 1024 * 2;
    void *pcmBuffer = malloc(pcmBufferSize);
    
    int i = 0;
    while((readed = fread(pcmBuffer, 1, pcmBufferSize, srcFile)) == pcmBufferSize && i < 2000) {
        NSData *data = [self.aacEncoder encodeWithPCMBuffer:pcmBuffer];
        if(data.length > 0) {
#ifdef kWriteLen
            uint32_t len = (uint32_t)data.length;
            fwrite(&len, 1, sizeof(uint32_t), dstFile);
#endif
            fwrite([data bytes], 1, data.length, dstFile);
        }
        i++;
    }

    free(pcmBuffer);
    fclose(srcFile);
    fclose(dstFile);
}

- (IBAction)actionButton3:(id)sender {
    NSString *srcFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音(含包长).aac"];
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音(重解码).pcm"];

    NSLog(@"%@", dstFilePath);

    self.aacDecoder = [[FFmpegAACDecoder alloc] init];

    FILE *srcFile = fopen([srcFilePath UTF8String], "rb");
    if(!srcFilePath) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }
    FILE *dstFile = fopen([dstFilePath UTF8String], "wb");
    if(!dstFile) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }
    
    void *buffer = malloc(1024 * 10);

    uint32_t len;
    int i = 0;
    __unused NSMutableData *aacData;
    while(fread(&len, sizeof(uint32_t), 1, srcFile) == 1 && len < 1024 * 10) {
        if(fread(buffer, 1, len, srcFile) == len) {
            i++;
            // 双包解码(新版 FFmpeg 不容易支持)
            /*
            if(i % 2 == 1) {
                aacData = [NSMutableData dataWithData:[NSData dataWithBytes:buffer length:len]];
            } else {
                [aacData appendData:[NSData dataWithBytes:buffer length:len]];
                NSData *pcmData = [self.aacDecoder decodeWithData:aacData];
                fwrite([pcmData bytes], 1, pcmData.length, dstFile);
            }
            //*/
            // 单包解码
            //*
            NSData *pcmData = [self.aacDecoder decodeWithData:[NSData dataWithBytes:buffer length:len]];
            fwrite([pcmData bytes], 1, pcmData.length, dstFile);
            //*/

        } else {
            break;
        }
    }
    
    NSLog(@"Finished");

    free(buffer);
    fclose(srcFile);
    fclose(dstFile);

}

- (IBAction)actionButton4:(id)sender {
    NSString *srcFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音(含包长).aac"];
    NSString *dstFilePath = [ViewController pathAtAppFiles:@"booty music 男女双声道混音(重解码ac).pcm"];
    
    NSLog(@"%@", dstFilePath);
    
    self.acAACDecoder = [[AudioConverterAACDecoder alloc] init];
    
    FILE *srcFile = fopen([srcFilePath UTF8String], "rb");
    if(!srcFilePath) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }
    FILE *dstFile = fopen([dstFilePath UTF8String], "wb");
    if(!dstFile) {
        NSLog(@"%@", @"Cannot open file");
        return;
    }

    void *buffer = malloc(1024 * 10);
    
    uint32_t len;
    int i = 0;
    __unused NSMutableData *aacData;
    while(fread(&len, sizeof(uint32_t), 1, srcFile) == 1 && len < 1024 * 10) {
        if(fread(buffer, 1, len, srcFile) == len) {
            i++;
            // 双包解码(AudioConverter需要知道有多少包)
            /*
            if(i % 2 == 1) {
                aacData = [NSMutableData dataWithData:[NSData dataWithBytes:buffer length:len]];
            } else {
                [aacData appendData:[NSData dataWithBytes:buffer length:len]];
                NSData *pcmData = [self.auAACDecoder decodeWithData:aacData];
                fwrite([pcmData bytes], 1, pcmData.length, dstFile);
            }
            //*/
            // 单包解码
            //*
             NSData *pcmData = [self.acAACDecoder decodeWithData:[NSData dataWithBytes:buffer length:len] start:7];
             fwrite([pcmData bytes], 1, pcmData.length, dstFile);
            //*/
            
        } else {
            break;
        }
    }
    
    NSLog(@"Finished");
    
    free(buffer);
    fclose(srcFile);
    fclose(dstFile);

}

- (IBAction)actionButton5:(id)sender {
#define USE_PTS
    
    FFmpegMP4Writer *writer = [[FFmpegMP4Writer alloc] init];
#ifdef USE_PTS
    [writer beginWriteUseAACWithVideoFrameRate:25 width:1280 height:720 sampleRate:44100 bitRate:64 * 1000 error:NULL];
#else
    [writer beginWriteUnusedAudioWithVideoFrameRate:25 width:1280 height:720 error:NULL];
#endif
    NSString *path = [[NSBundle mainBundle] pathForResource:@"暧昧" ofType:@"data"];
    FILE *file = fopen([path UTF8String], "r");
    TBMVideoFrameHeader head;
    while (fread(&head, sizeof(head), 1, file) != 0) {
        //NSLog(@"frame: %d %u", head.frameType, head.frameLength);
        uint8_t *frame = malloc(head.frameLength + sizeof(uint64_t));
        fread(frame, head.frameLength + sizeof(uint64_t), 1, file);
        if(head.frameType == 10 || head.frameType == 9) {
#ifdef USE_PTS
            //*
            int64_t pts = *((int64_t *)frame);
            [writer writeFrame:head.frameType == 10 ? TBMFrameTypeVideoI : TBMFrameTypeVideoP
                     frameData:frame
                  frameDataLen:head.frameLength
                         start:sizeof(uint64_t)
                           pts:pts
                         error:NULL];
            //*/
#else
            /*
             [writer writeFrame:head.frameType == 10 ? TBMFrameTypeVideoI : TBMFrameTypeVideoP
             frameData:frame
             frameDataLen:head.frameLength
             start:sizeof(uint64_t)
             error:NULL];
             //*/
#endif
        } else {
#ifdef USE_PTS
            int64_t pts = *((int64_t *)frame);
            [writer writeFrame:TBMFrameTypeAudio
                     frameData:frame
                  frameDataLen:head.frameLength
                         start:sizeof(uint64_t)
                           pts:pts
                         error:NULL];
#endif
        }
        free(frame);
    }
    
    [writer endWrite:NULL];
    [writer saveVideo:NULL];
    
    fclose(file);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (NSString *)pathAtAppFiles:(NSString *)fileName {
    //1、获取目录
    //获取Documents文件夹目录
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [path objectAtIndex:0];
    //指定新建文件夹路径
    NSString *appFiles = [documentPath stringByAppendingPathComponent:@"AppFiles"];
    
    //2、获取文件路径
    //返回保存文件的路径（文件保存在AppFiles文件夹下）
    NSString * filePath = [appFiles stringByAppendingPathComponent:fileName];
    
    //3、文件管理器（创建目录）
    //获取文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //创建AppFiles文件夹
    [fileManager createDirectoryAtPath:appFiles withIntermediateDirectories:YES attributes:nil error:nil];
    
    //DLog(@"getFilePath:%@",filePath);
    return filePath;
}


@end
