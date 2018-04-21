//
//  PIVoiceRecordView.h
//  Pinch
//
//  Created by li on 2018/3/13.
//  Copyright © 2018年 youweikeji. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordView : UIView

@end

typedef NS_ENUM(NSInteger, PIVoiceRecordViewState)
{
    PIVoiceRecordViewStateReady = 0, ///<准备状态
    PIVoiceRecordViewStateRecording = 1, ///<录制状态
    PIVoiceRecordViewStateReplaying =2, ///<播放状态
    PIVoiceRecordViewStateFinish =3, ///<录制完成状态
};

@protocol PIVoiceRecordViewDelegate <NSObject>

@optional;
/**
 改变录制状态

 @param start 开始/结束
 */
- (void)voiceRecordViewRecordAction:(BOOL)start;


/**
 开始录制
 */
- (void)voiceRecordViewStartReplaying;


/**
 暂停
 */
- (void)voiceRecordViewPause:(BOOL)pause;


/**
 完成录制
 */
- (void)voiceRecordViewFinishRecording;


/**
 重新录制
 */
- (void)voiceRecordViewStartReRecording;

@end

@interface PIVoiceRecordView : UIView

@property (nonatomic, assign) PIVoiceRecordViewState state;
@property (nonatomic, weak) id<PIVoiceRecordViewDelegate>delegate;
/**
 初始化

 @param title 保存按钮标题
 @return self
 */
- (instancetype)initWithEnsureTitle:(NSString *)title frame:(CGRect)frame;

//录制动画
- (void)startRecordingAnimation;
- (void)stopRecordingAnimation;


//播放动画
- (void)startReplayingAnimation:(CGFloat)voiceDuration;
- (void)stopReplayingAnimation;

- (void)updateState:(PIVoiceRecordViewState)state seconds:(NSUInteger)seconds; //更新录制状态
@end
