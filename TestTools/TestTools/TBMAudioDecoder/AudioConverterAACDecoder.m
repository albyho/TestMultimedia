//
//  AudioConverterAACDecoder.m
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "AudioConverterAACDecoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMedia/CoreMedia.h>
#import "ProjectUtils.h"
#import "TBMDefines.h"
#import "NSMutableData+SnapAdditions.h"

#define kAudioConverterAACDecoderPCMPacketLength    (1024 * 2)
#define kAudioConverterAACDecoderSampleRate         44100

typedef struct {
    AudioStreamBasicDescription       inAudioStreamBasicDescription; // PCM音频描述
    AudioStreamBasicDescription      outAudioStreamBasicDescription; // AAC音频描述
    AudioStreamPacketDescription         inputPacketDescriptions[1];
    AudioStreamPacketDescription        outputPacketDescriptions[1];
    AudioBufferList                               inAudioBufferList; // AAC数据缓存，用于输入
    
} AudioConverterSettings;

OSStatus AudioConverterAACDecoderComplexInputDataProc(AudioConverterRef                    inAudioConverter,
                                                      UInt32*                              ioNumberDataPackets,
                                                      AudioBufferList*                     ioData,
                                                      AudioStreamPacketDescription**       outDataPacketDescription,
                                                      void*                                inUserData)

{
    AudioConverterSettings *settings = (AudioConverterSettings*)inUserData;
    
    //*ioNumberDataPackets = 1; // 总是 1 包输入、1 包输出
    
    ioData->mBuffers[0].mNumberChannels = settings->inAudioBufferList.mBuffers[0].mNumberChannels;
    ioData->mBuffers[0].mData           = settings->inAudioBufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize   = settings->inAudioBufferList.mBuffers[0].mDataByteSize;
    
    /* And set the packet description */
    if (outDataPacketDescription) {
        settings->inputPacketDescriptions[0].mStartOffset            = 0;
        settings->inputPacketDescriptions[0].mVariableFramesInPacket = 0;
        settings->inputPacketDescriptions[0].mDataByteSize           = settings->inAudioBufferList.mBuffers[0].mDataByteSize;
        *outDataPacketDescription = settings->inputPacketDescriptions;
    }
    
    return noErr;
}

@interface AudioConverterAACDecoder ()
{
    AudioConverterSettings                                 _settings;
    AudioConverterRef                                _audioConverter; // 音频转换器
    AudioBufferList                                   _pcmBufferList; // PCM数据缓存，用于出
}

@end

@implementation AudioConverterAACDecoder

- (instancetype)init {
    self = [super init];
    if(self) {
        [self createAudioConverter];
    }
    return self;
}

- (BOOL)createAudioConverter {
    // Input audio format
    AudioStreamBasicDescription inAudioStreamBasicDescription = {0};
    inAudioStreamBasicDescription.mSampleRate = kAudioConverterAACDecoderSampleRate;
    inAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;
    inAudioStreamBasicDescription.mBytesPerPacket = 0;
    inAudioStreamBasicDescription.mFramesPerPacket = 1024;
    inAudioStreamBasicDescription.mBytesPerFrame = 0;
    inAudioStreamBasicDescription.mChannelsPerFrame = 1;
    inAudioStreamBasicDescription.mBitsPerChannel = 0;
    inAudioStreamBasicDescription.mReserved = 0;
    _settings.inAudioStreamBasicDescription = inAudioStreamBasicDescription;
    
    // Output audio format
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
    outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
    outAudioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM;
    outAudioStreamBasicDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    outAudioStreamBasicDescription.mBytesPerPacket = 2;
    outAudioStreamBasicDescription.mFramesPerPacket = 1;
    outAudioStreamBasicDescription.mBytesPerFrame = 2;
    outAudioStreamBasicDescription.mChannelsPerFrame = 1;
    outAudioStreamBasicDescription.mBitsPerChannel = 16;
    outAudioStreamBasicDescription.mReserved = 0;
    _settings.outAudioStreamBasicDescription = outAudioStreamBasicDescription;
    
    // Converter
    /* 1. 使用软解码
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (!description) {
        DLog(@"error creating audio class description");
        return NO;
    }
    OSStatus st = AudioConverterNewSpecific(&inAudioStreamBasicDescription, &outAudioStreamBasicDescription, 1, description, &_audioConverter);
    if (st) {
        DLog(@"error creating audio converter(%d)",(int)st);
        return NO;
    }
    //*/
    
    //* 2. 使用硬解码
    OSStatus st = AudioConverterNew(&_settings.inAudioStreamBasicDescription, &_settings.outAudioStreamBasicDescription, &_audioConverter);
    if (st) {
        DLog(@"error creating audio converter(%d)",(int)st);
        return NO;
    }
    //*/
    
    /* get actual format descriptors */
    UInt32 sizeOfASBD = sizeof(_settings.inAudioStreamBasicDescription);
    AudioConverterGetProperty(_audioConverter, kAudioConverterCurrentInputStreamDescription,
                              &sizeOfASBD, &_settings.inAudioStreamBasicDescription);
    sizeOfASBD = sizeof(_settings.outAudioStreamBasicDescription);
    AudioConverterGetProperty(_audioConverter, kAudioConverterCurrentOutputStreamDescription,
                              &sizeOfASBD, &_settings.outAudioStreamBasicDescription);
    
    // input buffer
    _settings.inAudioBufferList.mNumberBuffers = 1;
    _settings.inAudioBufferList.mBuffers[0].mNumberChannels = _settings.inAudioStreamBasicDescription.mChannelsPerFrame;

    // output buffer
    _pcmBufferList.mNumberBuffers = 1;
    _pcmBufferList.mBuffers[0].mNumberChannels = _settings.outAudioStreamBasicDescription.mChannelsPerFrame;
    _pcmBufferList.mBuffers[0].mData = malloc(kAudioConverterAACDecoderPCMPacketLength);
    _pcmBufferList.mBuffers[0].mDataByteSize = kAudioConverterAACDecoderPCMPacketLength;

    return YES;
}

- (NSData *)decodeWithData:(NSData *)frameData {
    return [self decodeWithData:frameData start:0];
}

- (NSData *)decodeWithData:(NSData *)frameData
                     start:(NSUInteger)start {
    if(!_audioConverter || !frameData || start > frameData.length - 10)
        return nil;
    
    _settings.inAudioBufferList.mBuffers[0].mData = (void *)[frameData bytes] + start;
    _settings.inAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)(frameData.length - start);
    
    // _pcmBufferList.mBuffers[0].mDataByteSize有两个作用，转换之前指示空Buffer的长度，转换之后指示数据的长度。
    _pcmBufferList.mBuffers[0].mDataByteSize = kAudioConverterAACDecoderPCMPacketLength;
    UInt32 ioOutputDataPacketSize = kAudioConverterAACDecoderPCMPacketLength / _settings.outAudioStreamBasicDescription.mBytesPerPacket;
    OSStatus st = AudioConverterFillComplexBuffer(_audioConverter,
                                                  AudioConverterAACDecoderComplexInputDataProc,
                                                  &_settings,
                                                  &ioOutputDataPacketSize,
                                                  &_pcmBufferList,
                                                  _settings.outputPacketDescriptions);
    if (st != noErr) {
        //[self printStatus:st];
        DLog(@"error convert: AudioConverterFillComplexBuffer(%d)", (int)st);
        return nil;
    }
    if (ioOutputDataPacketSize != _settings.inAudioStreamBasicDescription.mFramesPerPacket) {
        DLog(@"error convert: ioOutputDataPacketSize");
        return nil;
    }

    // _pcmBufferList.mBuffers复用，将数据拷贝
    NSData *pcm = [NSData dataWithBytes:_pcmBufferList.mBuffers[0].mData length:_pcmBufferList.mBuffers[0].mDataByteSize];
    return pcm;
}

- (void)dealloc {
    DLog(@"%@", __FUNCTION_FILE_LINE__);
    if(_audioConverter) {
        AudioConverterDispose(_audioConverter);
    }
    if(_pcmBufferList.mBuffers[0].mData) {
        free(_pcmBufferList.mBuffers[0].mData);
        _pcmBufferList.mBuffers[0].mData = NULL;
    }
}

#pragma mark - Helper
- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Decoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        DLog(@"error getting audio format propery info(%d)", (int)st);
        return NULL;
    }

    UInt32 count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Decoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        DLog(@"error getting audio format propery(%d)", (int)st);
        return NULL;
    }
    
    for (UInt32 i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return NULL;
}

- (void)printStatus:(OSStatus)status {
    if(status ==  noErr) return;
    
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(status);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
        DLog(@"error: %s", errorString);
    } else {
        // no, format it as an integer
        DLog(@"error %d", (int)status);
    }
}

- (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    DLog(@"Sample Rate:         %10.0f",  asbd.mSampleRate);
    DLog(@"Format ID:           %10s",    formatID);
    DLog(@"Format Flags:        %10X",    (unsigned int)asbd.mFormatFlags);
    DLog(@"Bytes per Packet:    %10d",    (unsigned int)asbd.mBytesPerPacket);
    DLog(@"Frames per Packet:   %10d",    (unsigned int)asbd.mFramesPerPacket);
    DLog(@"Bytes per Frame:     %10d",    (unsigned int)asbd.mBytesPerFrame);
    DLog(@"Channels per Frame:  %10d",    (unsigned int)asbd.mChannelsPerFrame);
    DLog(@"Bits per Channel:    %10d",    (unsigned int)asbd.mBitsPerChannel);
}

@end
