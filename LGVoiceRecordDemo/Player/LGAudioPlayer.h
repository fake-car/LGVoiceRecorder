//
//  LGAudioPlayer.h
//  LGVoiceRecordDemo
//
//  Created by inter on 2018/4/21.
//  Copyright © 2018年 inter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
typedef void(^PlayCompleteBlock)(void);

typedef void(^StartPlayingBlock)(AVPlayerItemStatus status, CGFloat duration);

typedef void(^AudioPlayingBlock)(CGFloat currentTime);


@interface LGAudioPlayer : NSObject

/**
 播放完成回调
 */
@property (nonatomic, copy) PlayCompleteBlock playComplete;

/**
 开始播放回调
 */
@property (nonatomic, copy) StartPlayingBlock startPlaying;

@property (nonatomic, copy) AudioPlayingBlock playingBlock;

@property (nonatomic, assign) NSUInteger currentTime; //当前播放时间

@property (nonatomic, assign) BOOL isPlaying; //播放中

@property (nonatomic, assign) BOOL isLocalFile; ///< 是否是本地文件

@property (nonatomic, copy) NSString *url;

/**
 开始播放音频文件
 
 @param urlStr url
 @param isLocalFile 是否是本地文件
 */
- (void)startPlayWithUrl:(NSString *)urlStr isLocalFile:(BOOL)isLocalFile;



- (void)pause:(BOOL)pause;

/**
 停止播放
 */
- (void)stopPlaying;

@end

