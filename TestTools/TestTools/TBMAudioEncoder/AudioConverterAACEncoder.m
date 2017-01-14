//
//  AudioConverterAACEncoder.m
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "AudioConverterAACEncoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMedia/CoreMedia.h>
#import "ProjectUtils.h"
#import "TBMDefines.h"
#import "NSMutableData+SnapAdditions.h"

#define kAudioConverterAACEncoderBitRate            (64 * 1000)
#define kAudioConverterAACEncoderPCMPacketLength    (1024 * 2)
#define kAudioConverterAACEncoderSampleRate         44100
#define kAudioConverterAACEncoderChannelCount       1
#define kAudioConverterAACEncoderADTSPacketLength   7

OSStatus AudioConverterAACEncoderComplexInputDataProc(AudioConverterRef                    inAudioConverter,
                                                      UInt32*                              ioNumberDataPackets,
                                                      AudioBufferList*                     ioData,
                                                      AudioStreamPacketDescription**       outDataPacketDescription,
                                                      void*                                inUserData)

{
    // TODO: 允许每次少于 1024 个采样
    AudioBufferList bufferList = *(AudioBufferList*)inUserData;
    
    //*ioNumberDataPackets = 1; // 总是 1 包输入、1 包输出
    
    ioData->mBuffers[0].mNumberChannels = bufferList.mBuffers[0].mNumberChannels;
    ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;

    return noErr;
}

@interface AudioConverterAACEncoder ()
{
    AudioStreamBasicDescription       _inAudioStreamBasicDescription; // PCM音频描述
    AudioStreamBasicDescription      _outAudioStreamBasicDescription; // AAC音频描述
    AudioConverterRef                                _audioConverter; // 音频转换器
    AudioBufferList                                   _pcmBufferList; // PCM数据缓存，用于输入
    AudioBufferList                                   _aacBufferList; // AAC数据缓存，用于输出
    UInt32                                  _maximumOutputPacketSize; // 每次转换之前需赋值
    AudioBuffer                                       _tempPCMBuffer; // 临时PCM数据缓存(使用1024个采样，缓冲2048Byte)
}

@end

@implementation AudioConverterAACEncoder

- (instancetype)init {
    self = [super init];
    if(self) {
        
    }
    return self;
}

- (BOOL)createAudioConverterWithASBD:(AudioStreamBasicDescription)inAudioStreamBasicDescription {
    // Input audio format
    _inAudioStreamBasicDescription = inAudioStreamBasicDescription;
    
    // Output audio format
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0}; // Always initialize the fields of a new audio stream basic description structure to zero, as shown here: ...
    outAudioStreamBasicDescription.mSampleRate = _inAudioStreamBasicDescription.mSampleRate; // The number of frames per second of the data in the stream, when the stream is played at normal speed. For compressed formats, this field indicates the number of frames per second of equivalent decompressed data. The mSampleRate field must be nonzero, except when this structure is used in a listing of supported formats (see “kAudioStreamAnyRate”).
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;// kAudioFormatMPEG4AAC_HE does not work. Can't find `AudioClassDescription`. `mFormatFlags` is set to 0.
    //outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC; // Format-specific flags to specify details of the format. Set to 0 to indicate no format flags. See “Audio Data Format Identifiers” for the flags that apply to each format.
    outAudioStreamBasicDescription.mBytesPerPacket = 0; // The number of bytes in a packet of audio data. To indicate variable packet size, set this field to 0. For a format that uses variable packet size, specify the size of each packet using an AudioStreamPacketDescription structure.
    outAudioStreamBasicDescription.mFramesPerPacket = 1024; // The number of frames in a packet of audio data. For uncompressed audio, the value is 1. For variable bit-rate formats, the value is a larger fixed number, such as 1024 for AAC. For formats with a variable number of frames per packet, such as Ogg Vorbis, set this field to 0.
    outAudioStreamBasicDescription.mBytesPerFrame = 0; // The number of bytes from the start of one frame to the start of the next frame in an audio buffer. Set this field to 0 for compressed formats. ...
    outAudioStreamBasicDescription.mChannelsPerFrame = 1; // The number of channels in each frame of audio data. This value must be nonzero.
    outAudioStreamBasicDescription.mBitsPerChannel = 0; // ... Set this field to 0 for compressed formats.
    outAudioStreamBasicDescription.mReserved = 0; // Pads the structure out to force an even 8-byte alignment. Must be set to 0.
    _outAudioStreamBasicDescription = outAudioStreamBasicDescription;

    // Converter
    // 使用软编码
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (!description) {
        DLog(@"error creating audio class description");
        return NO;
    }
    OSStatus st = AudioConverterNewSpecific(&_inAudioStreamBasicDescription, &_outAudioStreamBasicDescription, 1, description, &_audioConverter);
    if (st) {
        DLog(@"error creating audio converter(%d)",(int)st);
        return NO;
    }
    
    /* set conversion parameters */
    /*
    UInt32 tmp = kAudioCodecBitRateControlMode_VariableConstrained;
    st = AudioConverterSetProperty(_audioConverter, kAudioCodecPropertyBitRateControlMode,sizeof(tmp), &tmp);
    */
    
    UInt32 quality = kAudioConverterQuality_High;
    st = AudioConverterSetProperty(_audioConverter, kAudioConverterCodecQuality, sizeof(quality), &quality);
    if (st) {
        DLog(@"error set audio converter kAudioConverterCodecQuality property(%d)",(int)st);
        return NO;
    }
    
    UInt32 bitRate = kAudioConverterAACEncoderBitRate;
    st = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, sizeof(bitRate), &bitRate);
    if (st) {
        DLog(@"error set audio converter kAudioConverterEncodeBitRate property(%d)",(int)st);
        return NO;
    }
    
    /* get actual format descriptors */
    UInt32 sizeOfASBD = sizeof(_inAudioStreamBasicDescription);
    AudioConverterGetProperty(_audioConverter, kAudioConverterCurrentInputStreamDescription,
                              &sizeOfASBD, &_inAudioStreamBasicDescription);
    sizeOfASBD = sizeof(_outAudioStreamBasicDescription);
    AudioConverterGetProperty(_audioConverter, kAudioConverterCurrentOutputStreamDescription,
                              &sizeOfASBD, &_outAudioStreamBasicDescription);

    UInt32 maximumOutputPacketSize = 0;
    UInt32 maximumOutputPacketSizeDataSize = sizeof(maximumOutputPacketSize);
    st = AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &maximumOutputPacketSizeDataSize, &maximumOutputPacketSize);
    _maximumOutputPacketSize = maximumOutputPacketSize;
    // temp buffer
    _tempPCMBuffer.mNumberChannels = kAudioConverterAACEncoderChannelCount;
    _tempPCMBuffer.mData = malloc(kAudioConverterAACEncoderPCMPacketLength);
    // 注意，_tempPCMBufferList中的mDataByteSize，表示实际数据长度
    _tempPCMBuffer.mDataByteSize = 0;
    
    // input buffer
    _pcmBufferList.mNumberBuffers = 1;
    _pcmBufferList.mBuffers[0].mNumberChannels = kAudioConverterAACEncoderChannelCount;
    _pcmBufferList.mBuffers[0].mData = malloc(kAudioConverterAACEncoderPCMPacketLength);
    // 注意，_pcmBufferList中的mDataByteSize，总是固定值
    _pcmBufferList.mBuffers[0].mDataByteSize = kAudioConverterAACEncoderPCMPacketLength;

    // output buffer
    _aacBufferList.mNumberBuffers = 1;
    _aacBufferList.mBuffers[0].mNumberChannels = kAudioConverterAACEncoderChannelCount;
    _aacBufferList.mBuffers[0].mData = malloc(maximumOutputPacketSize);
    // 注意，_aacBufferList中的mDataByteSize，在输入时表示缓冲区长度，转换成功后表示实际数据
    _aacBufferList.mBuffers[0].mDataByteSize = maximumOutputPacketSize;

    return YES;
}

- (NSMutableData *)encodeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_audioConverter) {
        /* 在已知iOS设备上，ASBD如下：
        AudioStreamBasicDescription inAudioStreamBasicDescription = {0};
        inAudioStreamBasicDescription.mSampleRate = kAudioUnitAACConverterSampleRate;
        inAudioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM;
        inAudioStreamBasicDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        inAudioStreamBasicDescription.mBytesPerPacket = 2;
        inAudioStreamBasicDescription.mFramesPerPacket = 1;
        inAudioStreamBasicDescription.mBytesPerFrame = 2;
        inAudioStreamBasicDescription.mChannelsPerFrame = 1;
        inAudioStreamBasicDescription.mBitsPerChannel = 16;
        inAudioStreamBasicDescription.mReserved = 0;
        //*/
        
        // Input audio format
        AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
        if(![self createAudioConverterWithASBD:inAudioStreamBasicDescription]) {
            return nil;
        }
    }
    /*
    OSStatus st;
    Boolean dataIsReady = CMSampleBufferDataIsReady(sampleBuffer);
    Boolean isValid = CMSampleBufferIsValid(sampleBuffer);
    Boolean hasDataFailed = CMSampleBufferHasDataFailed(sampleBuffer, &st);
    */
    
    CMTime prestime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    Float64 pts = CMTimeGetSeconds(prestime);
    
    /* 1.
    AudioBufferList inAudioBufferList;
    inAudioBufferList.mNumberBuffers = 1;
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffset;
    CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, (size_t *)&inAudioBufferList.mBuffers[0].mDataByteSize, (char **)&inAudioBufferList.mBuffers[0].mData);
    inAudioBufferList.mBuffers[0].mNumberChannels = 1;
    NSMutableData *result = [self convertWithAudioBufferList:inAudioBufferList pts:pts];
    //*/
    
    //* 2.
    AudioBufferList inAudioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inAudioBufferList, sizeof(inAudioBufferList), NULL, NULL, 0, &blockBuffer);
    NSMutableData *result = [self encodeWithAudioBufferListInternal:inAudioBufferList pts:pts];
    CFRelease(blockBuffer);
    //*/
    
    /* 3.
    DataBuffer pcmBuffer; // pcmBuffer.mData不用释放
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &pcmBuffer.mDataByteSize, (char **)&pcmBuffer.mData);
    NSMutableData *result = [self convertWithPCMBuffer:pcmBuffer pts:pts];
    //*/
    
    //DLog(@"convertWithSampleBuffer %u -> %ld %lf", (unsigned int)inAudioBufferList.mBuffers[0].mDataByteSize, result.length, pts);
    return result;
}

- (NSMutableData *)encodeWithAudioBufferListInternal:(AudioBufferList)inAudioBufferList
                                                  pts:(Float64)pts {
    if(inAudioBufferList.mNumberBuffers != 1) {
        DLog(@"error inAudioBufferList.mNumberBuffers != 1");
        return nil;
    }
    if(inAudioBufferList.mBuffers[0].mData == NULL) {
        DLog(@"error inAudioBufferList.mBuffers[0].mData == NULL");
        return nil;
    }
    if(inAudioBufferList.mBuffers[0].mDataByteSize > kAudioConverterAACEncoderPCMPacketLength) {
        DLog(@"error inAudioBufferList.mBuffers[0].mDataByteSize(%d) > kAudioUnitAACConverterPCMPacketLength(%d)",
             (unsigned int)inAudioBufferList.mBuffers[0].mDataByteSize,
             kAudioConverterAACEncoderPCMPacketLength);
        return nil;
    }
    
    if(_tempPCMBuffer.mDataByteSize + inAudioBufferList.mBuffers[0].mDataByteSize == kAudioConverterAACEncoderPCMPacketLength) { // 数据刚刚好
        // 数据拷贝
        if (_tempPCMBuffer.mDataByteSize > 0) {
            memcpy(_pcmBufferList.mBuffers[0].mData,
                   _tempPCMBuffer.mData,
                   _tempPCMBuffer.mDataByteSize);
        }
        memcpy(_pcmBufferList.mBuffers[0].mData + _tempPCMBuffer.mDataByteSize,
               inAudioBufferList.mBuffers[0].mData,
               inAudioBufferList.mBuffers[0].mDataByteSize);
        
        // 重置临时Buffer
        if (_tempPCMBuffer.mDataByteSize > 0) {
            _tempPCMBuffer.mDataByteSize = 0;
        }
        
    } else if(_tempPCMBuffer.mDataByteSize + inAudioBufferList.mBuffers[0].mDataByteSize > kAudioConverterAACEncoderPCMPacketLength) { // 数据有多
        // 数据拷贝
        if (_tempPCMBuffer.mDataByteSize > 0) {
            memcpy(_pcmBufferList.mBuffers[0].mData,
                   _tempPCMBuffer.mData,
                   _tempPCMBuffer.mDataByteSize);
        }
        UInt32 newDataLength = kAudioConverterAACEncoderPCMPacketLength - _tempPCMBuffer.mDataByteSize;
        memcpy(_pcmBufferList.mBuffers[0].mData + _tempPCMBuffer.mDataByteSize,
               inAudioBufferList.mBuffers[0].mData,
               newDataLength);
        memcpy(_tempPCMBuffer.mData,
               inAudioBufferList.mBuffers[0].mData + newDataLength,
               inAudioBufferList.mBuffers[0].mDataByteSize - newDataLength);
        
        // 重置临时Buffer和pts
        if (_tempPCMBuffer.mDataByteSize > 0) {
            // 临时Buffer数据长度
            _tempPCMBuffer.mDataByteSize = inAudioBufferList.mBuffers[0].mDataByteSize - newDataLength;
        }
    } else { // 数据不够
        if(_tempPCMBuffer.mDataByteSize == 0) { // 如果原来没有数据,沿用当前pts
            memcpy(_tempPCMBuffer.mData,
                   inAudioBufferList.mBuffers[0].mData,
                   inAudioBufferList.mBuffers[0].mDataByteSize);
            _tempPCMBuffer.mDataByteSize = inAudioBufferList.mBuffers[0].mDataByteSize;
        } else { // 如果原来有未读数据拷贝新数据至临时Buffer尾部；不改变pts
            memcpy(_tempPCMBuffer.mData + _tempPCMBuffer.mDataByteSize,
                   inAudioBufferList.mBuffers[0].mData,
                   inAudioBufferList.mBuffers[0].mDataByteSize);
            _tempPCMBuffer.mDataByteSize += inAudioBufferList.mBuffers[0].mDataByteSize;
        }
        
        return nil;
    }
    
    // 如果数据有缓存，则pts会延迟一包数据
    NSMutableData *result = [self convertWithAudioBufferList:_pcmBufferList pts:pts];
    return result;
}

- (NSMutableData *)convertWithAudioBufferList:(AudioBufferList)inAudioBufferList
                                          pts:(Float64)pts {
    if(inAudioBufferList.mNumberBuffers != 1) {
        DLog(@"error inAudioBufferList.mNumberBuffers != 1");
        return nil;
    }
    if(inAudioBufferList.mBuffers[0].mData == NULL) {
        DLog(@"error inAudioBufferList.mBuffers[0].mData == NULL");
        return nil;
    }
    if(inAudioBufferList.mBuffers[0].mDataByteSize > kAudioConverterAACEncoderPCMPacketLength) {
        DLog(@"error inAudioBufferList.mBuffers[0].mDataByteSize > kAudioUnitAACConverterPCMPacketLength");
        return nil;
    }
    // _aacBufferList.mBuffers[0].mDataByteSize有两个作用，转换之前指示空Buffer的长度，转换之后指示数据的长度。
    _aacBufferList.mBuffers[0].mDataByteSize = _maximumOutputPacketSize;
    UInt32 ioOutputDataPacketSize = 1;
    OSStatus st = AudioConverterFillComplexBuffer(_audioConverter,
                                                  AudioConverterAACEncoderComplexInputDataProc,
                                                  &inAudioBufferList,
                                                  &ioOutputDataPacketSize,
                                                  &_aacBufferList, NULL);
    if (st != noErr) {
        DLog(@"error convert: AudioConverterFillComplexBuffer(%d) %lf", (int)st, pts);
        return nil;
    }
    if (ioOutputDataPacketSize == 0) {
        DLog(@"error convert: ioOutputDataPacketSize %lf", pts);
        return nil;
    }

    /* 不打包，直接返回aac
    NSData *aac = [NSData dataWithBytes:_aacBufferList.mBuffers[0].mData length:_aacBufferList.mBuffers[0].mDataByteSize];
    return aac;
    //*/

    //*
    const uint8_t frameType = TBMFrameTypeAudio;
    uint64_t ipts = (uint64_t)(pts * USEC_PER_SEC);
    // dataLength不包含pts的8个字节
    NSData *adts = [self getADTSDataWithPacketLength:_aacBufferList.mBuffers[0].mDataByteSize];
    uint32_t dataLength = kAudioConverterAACEncoderADTSPacketLength + _aacBufferList.mBuffers[0].mDataByteSize;
    
    NSMutableData *aacWithADTS = [NSMutableData dataWithCapacity:sizeof(uint8_t) + sizeof(uint32_t) + sizeof(uint64_t) + dataLength];
    [aacWithADTS rw_appendInt8:frameType];
    [aacWithADTS rw_appendInt32:dataLength];
    [aacWithADTS rw_appendInt64:ipts];
    [aacWithADTS appendData:adts];
    //[aacWithADTS appendBytes:adts length:kAudioUnitAACConverterADTSPacketLength];
    [aacWithADTS appendBytes:_aacBufferList.mBuffers[0].mData length:_aacBufferList.mBuffers[0].mDataByteSize];
    //free(adts);
    //adts = NULL;
    return aacWithADTS;
    //*/
}

- (void)dealloc {
    DLog(@"%@", __FUNCTION_FILE_LINE__);
    if(_audioConverter) {
        AudioConverterDispose(_audioConverter);
    }
    if(_tempPCMBuffer.mData) {
        free(_tempPCMBuffer.mData);
        _tempPCMBuffer.mData = NULL;
    }
    if(_pcmBufferList.mBuffers[0].mData) {
        free(_pcmBufferList.mBuffers[0].mData);
        _pcmBufferList.mBuffers[0].mData = NULL;
    }
    if (_aacBufferList.mBuffers[0].mData) {
        free(_aacBufferList.mBuffers[0].mData);
        _aacBufferList.mBuffers[0].mData = NULL;
    }
}

#pragma mark - Helper
- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        DLog(@"error getting audio format propery info(%d)", (int)st);
        return NULL;
    }
    
    UInt32 count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
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

/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData *)getADTSDataWithPacketLength:(UInt32)packetLength {
    const UInt8 adtsLength = kAudioConverterAACEncoderADTSPacketLength;    //ADTS长度                            固定为7
    const UInt8 profile = 1;                                       //Main: 00 LC: 01 SSR: 10 保留: 11    LC对应1，即01
    const UInt8 freqIdx = 4;                                       //Sampling Frequency Index           44100对应4，即0100
    const UInt8 chanCfg = 1;                                       //Channel Configuration              1声道对应1，即001
    const UInt32 fullLength = adtsLength + packetLength;
    UInt8 *adts = malloc(sizeof(UInt8) * adtsLength);
    // fill in ADTS data
    adts[0] = (UInt8)0xFF;     // 11111111     = syncword
    adts[1] = (UInt8)0xF1;     // 1111 0 00 1  = syncword(1111) MPEG-4(0) Layer(00) CRC(1)
    adts[2] = (UInt8)((profile << 6) + (freqIdx << 2) +(chanCfg >> 2));
    adts[3] = (UInt8)(((chanCfg & 3) << 6) + (fullLength >> 11));
    adts[4] = (UInt8)((fullLength & 0x7FF) >> 3);
    adts[5] = (UInt8)(((fullLength & 7) << 5) + 0x1F);
    adts[6] = (UInt8)0xFC;
    NSData *result = [NSData dataWithBytesNoCopy:adts length:adtsLength freeWhenDone:YES];
    return result;
    //return adts;
}

- (UInt32)getDataLengthWithADTS:(UInt8 *)adts {
    //const UInt32 chanCfg = 1;                                       //Channel Configuration              1声道对应1，即001
    //UInt32 result = ((((UInt32)adts[3] - ((chanCfg & 3) << 6)) << 11)) | ((UInt32)adts[4] << 3) | (((UInt32)adts[5] - 0x1F) >> 5);
    UInt32 result = ((((UInt32)adts[3] - 0x40) << 11)) | ((UInt32)adts[4] << 3) | (((UInt32)adts[5] - 0x1F) >> 5);
    return result;
}

@end
