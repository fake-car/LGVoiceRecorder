//
//  LGVoiceRecorder.h
//  LGVoiceRecordDemo
//
//  Created by inter on 2018/4/21.
//  Copyright © 2018年 inter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^VoiceRecorderStartRecordingBlock)(BOOL isSuccess); ///<开始录音回调
typedef void(^VoiceRecorderFinishRecordingBlock)(NSString *aacUrl, NSUInteger audioTimeLength); ///<录音结束回调
typedef void(^VoiceRecordingFailBlock)(NSString *reason);

@interface LGVoiceRecorder : NSObject
@property (nonatomic, copy) VoiceRecorderStartRecordingBlock audioStartRecording;
@property (nonatomic, copy) VoiceRecorderFinishRecordingBlock audioFinishRecording;
@property (nonatomic, copy) VoiceRecordingFailBlock audioRecordingFail;                      //录制时长过段失败回调
@property (nonatomic, assign) BOOL isRecording; ///<正在录制中

@property (nonatomic, assign) NSUInteger __block audioTimeLength; //录音时长
@property (nonatomic, assign) NSTimeInterval currentTime;


/**
 开始录制
 */
- (void)startRecording;


/**
 停止录制
 */
- (void)stopRecording;


/**
 重新录制
 */
- (void)reRecording;


@end
