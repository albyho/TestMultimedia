//
//  FFmpegAudioFileDecoder.m
//  ProjectLibrary
//
//  Created by alby on 2016/11/29.
//  Copyright © 2016年 alby. All rights reserved.
//

#import "FFmpegAudioFileDecoder.h"
#import "ProjectUtils.h"
#import "FFmpegPCMResampler.h"
#include <stdio.h>
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>
#include <libavformat/avformat.h>
#include <libavutil/fifo.h>

NSString *const FFmpegAudioFileDecoderErrorDomain = @"FFmpegAudioFileDecoderErrorDomain";

@interface FFmpegAudioFileDecoder ()
{
    dispatch_queue_t    _processQueue;

    FFmpegPCMResampler* _resampler;

    AVCodecContext      *_codecContext;
    AVFormatContext     *_formatContext;
    AVStream            *_audioStream;
    int                 _audioStreamIndex;
    
    AVFrame             *_frame;
    AVPacket            _packet;
    FILE                *_destinationFile;
}

@end

@implementation FFmpegAudioFileDecoder

+ (void)initialize {
    if (self == [FFmpegAudioFileDecoder class]) {
        //DLog(@"%s",__PRETTY_FUNCTION__);
        /* register all formats and codecs */
        av_register_all();
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _processQueue = dispatch_queue_create("com.ffmpegaudiofiledecoder.process", DISPATCH_QUEUE_SERIAL);
        _audioStreamIndex = -1;
    }
    return self;
}

- (BOOL)decodeWithSourceFilePath:(NSString *)sourceFilePath
             destinationFilePath:(NSString *)destinationFilePath
               completionHandler:(void (^)(void))completionHandler
                    errorHandler:(void (^)(NSError *error))errorHandler {

    //DLog(@"%s sourceFilePath:%@, destinationFilePath:%@", __FUNCTION__, sourceFilePath, destinationFilePath);
    
    if (sourceFilePath.length == 0 || destinationFilePath.length == 0) {
        //DLog(@"%s Arguments is wrong!", __FUNCTION__);
        NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                    code:0
                                userInfo:@{@"Message":@"Arguments is wrong!"}];
        errorHandler(error);
        return NO;
    }
    
    dispatch_async(_processQueue, ^{
        int res = 0;
        
        const char *sourceFilename = [sourceFilePath UTF8String];
        const char *destinationFilename =  [destinationFilePath UTF8String];
        
        /* open input file, and allocate format context */
        if ((res = avformat_open_input(&_formatContext, sourceFilename, NULL, NULL)) < 0) {
            //DLog(@"%s, avformat_open_input() Could not open source file %s (%s)", __FUNCTION__, sourceFilename, av_err2str(res));
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Could not open source file %s (%s)", sourceFilename, av_err2str(res)]}];
                errorHandler(error);
            });
            return;
        }
        
        // find streams information
        if ((res = avformat_find_stream_info(_formatContext, NULL) < 0)) {
            //DLog(@"%s, av_find_stream_info() Could not find codec parameters! (%s)", __FUNCTION__, av_err2str(res));
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Could not find codec parameters! (%s)", av_err2str(res)]}];
                errorHandler(error);
            });
            return;
        }
        
        /* dump input information to stderr */
        av_dump_format(_formatContext, 0, sourceFilename, 0);
        
        if((res = [self openCodecContext:sourceFilename
                      streamIndex:&_audioStreamIndex
                     codecContext:&_codecContext
                    formatContext:_formatContext
                        mediaType:AVMEDIA_TYPE_AUDIO]) == 0) {
            
            _audioStream = _formatContext->streams[_audioStreamIndex];
            if(!_audioStream) {
                //DLog(@"%s Could not open audio stream %s", __FUNCTION__, sourceFilename);
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                         code:0
                                                     userInfo:@{@"Message":[NSString stringWithFormat:@"Could not open audio stream %s", sourceFilename]}];
                    errorHandler(error);
                });
                return;
            }
            
            _destinationFile = fopen(destinationFilename, "w");
            if (!_destinationFile) {
                //DLog(@"%s Could not open destination file %s", __FUNCTION__, destinationFilename);
                [self cleanup];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                         code:0
                                                     userInfo:@{@"Message":[NSString stringWithFormat:@"Could not open destination file %s", destinationFilename]}];
                    errorHandler(error);
                });
                return;
            }
        }
        
        if(res < 0) {
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Could not open codec context %s", av_err2str(res)]}];
                errorHandler(error);
            });
            return;
        }
        
        _frame = av_frame_alloc();
        if (!_frame) {
            //DLog(@"%s av_frame_alloc() Could not allocate frame", __FUNCTION__);
            res = AVERROR(ENOMEM);
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Could not allocate frame (%s)", av_err2str(res)]}];
                errorHandler(error);
            });
            return;
        }
        
        /* initialize packet, set data to NULL, let the demuxer fill it */
        av_init_packet(&_packet);
        _packet.data = NULL;
        _packet.size = 0;
        
        /* read frames from the file */
        BOOL isReaded = NO;
        int readRes = 0;
        while ((readRes = av_read_frame(_formatContext, &_packet)) >= 0) {
            if(!isReaded) isReaded = YES;
            res = [self decodePacket:NO];
            if (res < 0) break;
            av_packet_unref(&_packet);
        }
        
        if(!isReaded && (readRes < 0)) {
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Error read audio frame (%s)", av_err2str(readRes)]}];
                errorHandler(error);
            });
            return;
        }
        
        if(res == 0) {
            /* flush cached frames */
            _packet.data = NULL;
            _packet.size = 0;
            res = [self decodePacket:YES];
        }
        
        if(res != 0) {
            [self cleanup];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:FFmpegAudioFileDecoderErrorDomain
                                                     code:0
                                                 userInfo:@{@"Message":[NSString stringWithFormat:@"Error decoding audio frame (%s)", av_err2str(res)]}];
                errorHandler(error);
            });
            return;
        }

        //DLog(@"Demuxing succeeded.");

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler();
        });
    });
    
    return YES;
}

- (int)openCodecContext:(const char *)sourceFilename
            streamIndex:(int *)streamIndex
           codecContext:(AVCodecContext **)codecContext
          formatContext:(AVFormatContext *)formatContext
              mediaType:(enum AVMediaType)mediaType {

    const int refcount = 0;
    
    int res;
    int streamIndexTemp;
    AVStream *stream;
    AVCodec *dec = NULL;
    AVDictionary *opts = NULL;
    
    res = av_find_best_stream(formatContext, mediaType, -1, -1, NULL, 0);
    if (res < 0) {
        //DLog(@"%s av_find_best_stream() Could not find %s stream in input file '%s'", __FUNCTION__, av_get_media_type_string(mediaType), sourceFilename);
        return res;
    } else {
        streamIndexTemp = res;
        stream = formatContext->streams[streamIndexTemp];
        
        /* find decoder for the stream */
        dec = avcodec_find_decoder(stream->codecpar->codec_id);
        if (!dec) {
            //DLog(@"%s avcodec_find_decoder() Failed to find %s codec", __FUNCTION__, av_get_media_type_string(mediaType));
            res = AVERROR(AVERROR_UNKNOWN);
            return res;
        }
        
        /* Allocate a codec context for the decoder */
        *codecContext = avcodec_alloc_context3(dec);
        if (!*codecContext) {
            //DLog(@"%s avcodec_alloc_context3() Failed to allocate the %s codec context", __FUNCTION__, av_get_media_type_string(mediaType));
            res = AVERROR(AVERROR_UNKNOWN);
            return res;
        }
        
        /* Copy codec parameters from input stream to output codec context */
        if ((res = avcodec_parameters_to_context(*codecContext, stream->codecpar)) < 0) {
            //DLog(@"%s avcodec_parameters_to_context() Failed to copy %s codec parameters to decoder context", __FUNCTION__, av_get_media_type_string(mediaType));
            return res;
        }
        
        /* Init the decoders, with or without reference counting */
        av_dict_set(&opts, "refcounted_frames", refcount ? "1" : "0", 0);
        if ((res = avcodec_open2(*codecContext, dec, &opts)) < 0) {
            //DLog(@"%s av_get_media_type_string() Failed to open %s codec", __FUNCTION__, av_get_media_type_string(mediaType));
            return res;
        }
        *streamIndex = streamIndexTemp;
    }
    
    return 0;
}

- (BOOL)getFormatWithSampleFormat:(enum AVSampleFormat)sampleFormat
                           format:(const char **)format {
    int i;
    struct sample_fmt_entry {
        enum AVSampleFormat sample_fmt; const char *fmt_be, *fmt_le;
    } sample_fmt_entries[] = {
        { AV_SAMPLE_FMT_U8,  "u8",    "u8"    },
        { AV_SAMPLE_FMT_S16, "s16be", "s16le" },
        { AV_SAMPLE_FMT_S32, "s32be", "s32le" },
        { AV_SAMPLE_FMT_FLT, "f32be", "f32le" },
        { AV_SAMPLE_FMT_DBL, "f64be", "f64le" },
    };
    *format = NULL;
    
    for (i = 0; i < FF_ARRAY_ELEMS(sample_fmt_entries); i++) {
        struct sample_fmt_entry *entry = &sample_fmt_entries[i];
        if (sampleFormat == entry->sample_fmt) {
            *format = AV_NE(entry->fmt_be, entry->fmt_le);
            return YES;
        }
    }
    
    //DLog(@"%s Sample format %s is not supported as output format", __FUNCTION__, av_get_sample_fmt_name(sampleFormat));
    return NO;
}

- (int)decodePacket:(BOOL)cached {
    
    int res = 0;
    
    /* decode audio frame */
    
    res = avcodec_send_packet(_codecContext, &_packet);
    if (res < 0 && res != AVERROR(EAGAIN) && res != AVERROR_EOF) {
        //DLog(@"%s avcodec_send_packet() Error decoding audio frame (%s)", __FUNCTION__, av_err2str(res));
        return res;
    }

    res = avcodec_receive_frame(_codecContext, _frame);
    if (res < 0 /*&& res != AVERROR(EAGAIN)*/ && res != AVERROR_EOF) {
        //DLog(@"%s avcodec_receive_frame() Error decoding audio frame (%s)", __FUNCTION__, av_err2str(res));
        return res;
    }
    
    // maybe flush
    if(_frame->nb_samples == 0) {
        return 0;
    };
    
    int64_t src_ch_layout = (_codecContext->channel_layout && _codecContext->channels == av_get_channel_layout_nb_channels(_codecContext->channel_layout)) ? _codecContext->channel_layout : av_get_default_channel_layout(_codecContext->channels);

    if(!_resampler) {
        _resampler = [[FFmpegPCMResampler alloc] initWithSrcChLayout:src_ch_layout
                                                       dst_ch_layout:AV_CH_LAYOUT_MONO
                                                      src_sample_fmt:_codecContext->sample_fmt
                                                      dst_sample_fmt:AV_SAMPLE_FMT_S16
                                                            src_rate:_codecContext->sample_rate
                                                            dst_rate:44100];
    }
    
    NSData *data = [_resampler resampleWithPCMBuffer:(void **)_frame->data sampleCount:_frame->nb_samples];
    fwrite([data bytes], 1, [data length], _destinationFile);
    
    return 0;
}

- (void)cleanup {
    
    if(_codecContext) {
        avcodec_free_context(&_codecContext);
    }
    
    if(_formatContext) {
        avformat_close_input(&_formatContext);
    }
    
    if(_frame) {
        av_frame_free(&_frame);
    }
    
    if(_destinationFile) {
        fclose(_destinationFile);
        _destinationFile = NULL;
    }
    
    _audioStreamIndex = -1;
}

- (void)dealloc {
    //DLog(@"%@", __FUNCTION_FILE_LINE__);
    [self cleanup];
}

@end
