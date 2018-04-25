
//
//  PIVoiceRecordViewController.m
//  Pinch
//
//  Created by li on 2018/3/13.
//  Copyright © 2018年 youweikeji. All rights reserved.
//

#import "PIVoiceRecordViewController.h"
#import "PIVoiceRecordView.h"
#import "LGAudioPlayer.h"
#import "LGVoiceRecorder.h"

#define kWidth     [UIScreen mainScreen].bounds.size.width
#define kHeight     [UIScreen mainScreen].bounds.size.height
@interface PIVoiceRecordViewController ()<PIVoiceRecordViewDelegate>
@property (nonatomic, strong) PIVoiceRecordView *voiceRecordView;
@property (nonatomic, strong) LGAudioPlayer *audioPlayer;
@property (nonatomic, strong) LGVoiceRecorder *recorder;
@property (nonatomic, strong) NSTimer *recordTimer; //录音定时器
@property (nonatomic, strong) NSString *localAACUrl; //aac地址
@property (nonatomic, copy) NSString *audioUrl; ///<音频url

@end

@implementation PIVoiceRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"录制声音";

    [self initViews];
    
    [self addNotification];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeNotification];
    [self destory];
    
}
- (void)initViews
{
    
    
    //录音视图
    self.voiceRecordView = [[PIVoiceRecordView alloc] initWithEnsureTitle:@"保存" frame:CGRectMake(0, (self.view.frame.size.height - 126) /2.0, kWidth, 126)];
    self.voiceRecordView.delegate = self;
    [self.view addSubview:self.voiceRecordView];
    
    
}
- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopContext) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}
//清除
- (void)stopContext
{
    [self stopRecordTimer];
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stopPlaying];
        
    }
    if (self.recorder.isRecording) {
        [self.recorder stopRecording];
        
    }
}
- (void)destory
{
    [self stopRecordTimer];
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stopPlaying];
        
    }
    if (self.recorder.isRecording) {
        [self.recorder stopRecording];
        
    } else {
        [self.recorder reRecording];
    }
    [self.voiceRecordView updateState:PIVoiceRecordViewStateReady seconds:0];
    self.audioPlayer = nil;
    self.recorder = nil;
    
    
}

#pragma mark - 音频录制播放逻辑
/************录音定时器*********************/
- (void)startRecordTimer
{
    [self stopRecordTimer];
    self.recordTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateRecordTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.recordTimer forMode:NSRunLoopCommonModes];
    [self.recordTimer fire];
}

- (void)stopRecordTimer
{
    if (self.recordTimer) {
        [self.recordTimer invalidate];
        self.recordTimer = nil;
    }
}
//更新录音时间
- (void)updateRecordTime
{
    if (self.recorder.currentTime == MAXRECORDTIME) {
        [self stopRecordTimer];
        [self.recorder stopRecording];
    }
    [self.voiceRecordView updateState:PIVoiceRecordViewStateRecording seconds:self.recorder.currentTime];
}

#pragma mark -PIVoiceRecordViewDelegate

/**
 改变录制状态
 
 @param start 开始/结束 录制
 */
- (void)voiceRecordViewRecordAction:(BOOL)start
{
    if (start) {
        //开始录制
        if (self.audioPlayer.isPlaying) {
            [self.audioPlayer stopPlaying];
        }
        [self.recorder startRecording];
    } else {
        //停止录制
        [self.recorder stopRecording];
    }
}


/**
 播放音频
 */
- (void)voiceRecordViewStartReplaying
{

    [self.audioPlayer startPlayWithUrl:self.localAACUrl isLocalFile:YES];
}


/**
 暂停
 */
- (void)voiceRecordViewPause:(BOOL)pause
{
    [self.audioPlayer pause:pause];
    
    
}


/**
 完成录制
 */
- (void)voiceRecordViewFinishRecording
{
    if (!self.localAACUrl) {
        return;
    }
}

/**
 重新录制
 */
- (void)voiceRecordViewStartReRecording
{
    if (!self.localAACUrl) {
        return;
    }
    UIAlertController *alertAC =  [UIAlertController alertControllerWithTitle:@"确定重录吗?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ensure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.audioPlayer.isPlaying) {
            [self.audioPlayer stopPlaying];
        }
        self.audioUrl = nil;
        self.localAACUrl = nil;
        [self.voiceRecordView stopReplayingAnimation];
        [self.recorder reRecording];
        [self.voiceRecordView updateState:PIVoiceRecordViewStateReady seconds:0];
    }];
    [alertAC addAction:cancel];
    [alertAC addAction:ensure];
    [self presentViewController:alertAC animated:YES completion:nil];
    
}



#pragma mark -setter and getter
- (LGVoiceRecorder *)recorder
{
    if (!_recorder) {
        _recorder = [[LGVoiceRecorder alloc] init];
        __weak typeof(self) weakSelf = self;

        //开始录音
        _recorder.audioStartRecording = ^(BOOL isSuccess) {
            if (isSuccess) {
                [weakSelf startRecordTimer];
                
                [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateRecording seconds:0];
                [weakSelf.voiceRecordView startRecordingAnimation];
            } else {
                NSLog(@"未获取到麦克风，请检查麦克风权限是否开启");
            }
        };
        
        //录音失败，时间过短
        _recorder.audioRecordingFail = ^(NSString *reason) {
            [weakSelf stopRecordTimer];
            [weakSelf.voiceRecordView stopRecordingAnimation];
            [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateReady seconds:0];
        };
        
        _recorder.audioFinishRecording = ^(NSString *aacUrl, NSUInteger audioTimeLength) {
            [weakSelf stopRecordTimer];
            [weakSelf.voiceRecordView stopRecordingAnimation];
            if (audioTimeLength<MINRECORDTIME) {
     
                NSLog(@"%@",[NSString stringWithFormat:@"声音不足%d秒，请重录", MINRECORDTIME]);
                weakSelf.localAACUrl = nil;
                weakSelf.audioUrl = nil;
                [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateReady seconds:0];
                return ;
            }
            weakSelf.localAACUrl = aacUrl;
            [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateFinish seconds:MIN(180, audioTimeLength)];
        };
        
    }
    return _recorder;
}

- (LGAudioPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        _audioPlayer = [[LGAudioPlayer alloc] init];
        __weak typeof(self) weakSelf = self;
        _audioPlayer.startPlaying = ^(AVPlayerItemStatus status, CGFloat duration) {
            if (status == AVPlayerItemStatusReadyToPlay) {
                if (weakSelf.audioPlayer.isLocalFile) {
                    //录音
                    
                    [weakSelf.voiceRecordView startReplayingAnimation:duration];
                    [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateFinish seconds:(NSInteger)duration];
                } else {
                    //网络
                    NSLog(@"duration %f",duration);
                }
                
            } else {
                if (status == AVPlayerItemStatusFailed) {
                    
                    NSLog(@"音频播放失败，请重试");
                }
                if (weakSelf.audioPlayer.isLocalFile) {
                    [weakSelf.voiceRecordView stopReplayingAnimation];
                    [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateFinish seconds:weakSelf.recorder.audioTimeLength];
                } else {
                    //网络音频
                }


            }
            
            
        };
        _audioPlayer.playComplete = ^{
            if (weakSelf.audioPlayer.isLocalFile) {
                [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateReplaying seconds:0];
                [weakSelf.voiceRecordView stopReplayingAnimation];
                
                [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateFinish seconds:weakSelf.recorder.audioTimeLength];
            } else {
                //网络
            }
        };
        _audioPlayer.playingBlock = ^(CGFloat currentTime) {
            if (weakSelf.audioPlayer.isLocalFile) {
                [weakSelf.voiceRecordView updateState:PIVoiceRecordViewStateReplaying seconds:currentTime];
            } else {
                //网络
            }
            
        };
    }
    return _audioPlayer;
}

@end
