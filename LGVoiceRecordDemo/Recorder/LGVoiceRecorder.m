
//
//  LGVoiceRecorder.m
//  LGVoiceRecordDemo
//
//  Created by inter on 2018/4/21.
//  Copyright © 2018年 inter. All rights reserved.
//

#import "LGVoiceRecorder.h"

#import <AVFoundation/AVFoundation.h>
#define AACFile @"temporaryRadio.aac"

@interface LGVoiceRecorder ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) NSFileManager *fileManager; ///<文件管理工具
@property (nonatomic, strong) AVAudioRecorder *recorder; ///<录制工具
@end

@implementation LGVoiceRecorder
- (void)dealloc
{
    if (self.isRecording) [self.recorder stop];
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        //清除之前的音频缓存
        self.currentTime = 0;
        self.audioTimeLength = 0;
        [self cleanCache];
    }
    return self;
}

- (void)cleanCache
{
    NSString *aacRecordFilePath = [NSTemporaryDirectory()stringByAppendingPathComponent:AACFile];
    
    if ([self.fileManager fileExistsAtPath:aacRecordFilePath]) {
        [self.fileManager removeItemAtPath:aacRecordFilePath error:nil];
    }
    //    if ([self.fileManager fileExistsAtPath:amrRecordFilePath]) {
    //        [self.fileManager removeItemAtPath:amrRecordFilePath error:nil];
    //    }
    
}

- (void)startRecording
{
    if (self.isRecording) {
        return;
    }
    
    //开始录音
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [self.recorder prepareToRecord];
    
    [self.recorder record];
    
    if ([self.recorder isRecording]) {
        self.isRecording = YES;
        if (self.audioStartRecording) {
            self.audioStartRecording(YES);
        }
        
    } else {
        if (self.audioStartRecording) {
            self.audioStartRecording(NO);
        }
    }
}

- (void)stopRecording
{
    if (!self.isRecording) {
        return;
    }
    
    self.audioTimeLength = self.recorder.currentTime;
    [self.recorder stop];
    self.isRecording = NO;
}

- (void)reRecording
{
    if (self.isRecording) {
        [self stopRecording];
    }
    self.audioTimeLength = 0;
    [self cleanCache];
    
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag) {
        //暂存录音文件路径
        NSString *aacRecordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:AACFile];
        
        //         AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:[NSURL URLWithString:aacRecordFilePath] options:opts];
        
        
        
        //         CMTime audioDuration = audioAsset.duration;
        
        
        
        //         float audioDurationSeconds =CMTimeGetSeconds(audioDuration);
        
        
        
        if (self.audioFinishRecording) {
            self.audioFinishRecording(aacRecordFilePath, self.audioTimeLength);
        }
        
        self.isRecording = NO;
    } else {
        if (self.audioRecordingFail) {
            self.audioRecordingFail(@"录音时长小于设定最短时长");
        }
    }
    
    
}

#pragma mark setter and getter
- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (NSTimeInterval)currentTime
{
    return self.recorder.isRecording ? self.recorder.currentTime :0.0;
}

- (AVAudioRecorder *)recorder
{
    if (!_recorder) {
        //暂存录音文件路径
        NSString *aacRecordFilePath = [NSTemporaryDirectory()stringByAppendingPathComponent:AACFile];
        
        NSDictionary *recordSetting = @{ AVSampleRateKey        : @44100,                      // 采样率
                                         AVFormatIDKey          : @(kAudioFormatMPEG4AAC),     // 音频格式
                                         AVLinearPCMBitDepthKey : @16,                          // 采样位数 默认 16
                                         AVNumberOfChannelsKey  : @1                            // 通道的数目
                                         };
        _recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:aacRecordFilePath] settings:recordSetting error:nil];
        
        _recorder.delegate = self;
    }
    return _recorder;
}
@end

