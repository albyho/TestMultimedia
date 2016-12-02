//
//  FAACAACEncoder.m
//  ProjectLibrary
//
//  Created by alby on 15/1/24.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "FAACAACEncoder.h"
#import "ProjectUtils.h"
#include <faac.h>

#define kFAACAACEncoderSampleRate      44100
#define kFAACAACEncoderChannelCount    1
#define kFAACAACEncoderBitDepth        16
#define kFAACAACEncoderSampleNumber    1024

@interface FAACAACEncoder ()
{
    unsigned long           _sampleRate;
    unsigned int            _channels;
    unsigned int            _bitDepth;
    unsigned long           _bitRate;
    unsigned long           _pcmSamples;
    unsigned long           _maxOutputSize;
    faacEncHandle           _encoder;
    faacEncConfigurationPtr _configuration;
    
    uint8_t                 *_pcmBuffer;
    size_t                  _pcmBufferSize;
}

@property (nonatomic, readwrite) uint8_t *aacBuffer;

@end

@implementation FAACAACEncoder

- (int)startup:(unsigned long)bitRate {
    [self shutdown];
    
    _sampleRate = kFAACAACEncoderSampleRate;
    _channels = kFAACAACEncoderChannelCount;
    _bitDepth = kFAACAACEncoderBitDepth;
    _bitRate = bitRate;
    
    // (1) Open FAAC engine
    _encoder = faacEncOpen(_sampleRate, _channels, &_pcmSamples, &_maxOutputSize);
    if(_encoder == NULL) {
        DLog(@"%@ Failed to call faacEncOpen()", __FUNCTION_FILE_LINE__);
        return 1;
    }
    // _pcmSamples:1024 _maxOutputSize:768
    
    // (2.1) Get current encoding configuration
    _configuration = faacEncGetCurrentConfiguration(_encoder);
    _configuration->mpegVersion = MPEG4;
    _configuration->aacObjectType = LOW;
    _configuration->inputFormat = FAAC_INPUT_16BIT;
    _configuration->useTns = 1;          // 时域噪音控制
    _configuration->bandWidth = 0;       // 频宽
    _configuration->quantqual = 100;     // 编码质量
    _configuration->bitRate = _bitRate;
    _configuration->outputFormat = 0;    // 0:Raw 1:ADTS
    
    // (2.2) Set encoding configuration
    /*int ret = */faacEncSetConfiguration(_encoder, _configuration);

    _pcmBufferSize = _pcmSamples * _channels * (_bitDepth / 8);
    _pcmBuffer = (uint8_t *)malloc(_pcmBufferSize);
    _aacBuffer = (uint8_t *)malloc(_maxOutputSize);

    return 0;
}

- (int)encodeWithPCMBuffer:(void *)pcmBuffer {
    if(_bitRate <= 0) {
        DLog(@"error:call startup first.");
        return 0;
    }
    
    // pcmBuffer必须为2048字节，这个由调用者来保证。inputSamples则为1024。
    const int inputSamples = kFAACAACEncoderSampleNumber; // 2048/(_bitDepth/8) = 2048/(16/8) = 1024
    
    int ret;
    // (3) Encode
    ret = faacEncEncode(_encoder, (int32_t *)pcmBuffer, inputSamples, _aacBuffer, (unsigned int)_maxOutputSize);
    
    return ret; // 返回0也正常
}

- (int)shutdown {
    if(_pcmBuffer) {
        free(_pcmBuffer);
        _pcmBuffer = NULL;
    }
    
    if(_aacBuffer) {
        free(_aacBuffer);
        _aacBuffer = NULL;
    }
    
    // (4) Close FAAC engine
    if(_encoder) {
        faacEncClose(_encoder);
    }
    
    _bitRate = 0;
    
    return 0;
}

- (void)dealloc {
    [self shutdown];
}

@end
