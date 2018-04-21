//
//  LGAudioPlayer.m
//  LGVoiceRecordDemo
//
//  Created by inter on 2018/4/21.
//  Copyright © 2018年 inter. All rights reserved.
//


#import "LGAudioPlayer.h"
@interface LGAudioPlayer ()<AVAudioPlayerDelegate>
@property (nonatomic, strong) NSFileManager *fileManager; //
@property (nonatomic, strong) AVAudioPlayer *audioPlayer; //音频播放器
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak) id observer;
@property (nonatomic, strong) AVPlayerItem *voiceItem;
@end

@implementation LGAudioPlayer
- (void)dealloc
{
    if (self.observer) {
        [self.player removeTimeObserver:self.observer];
        
    }
    [self removeObserver];
    [self.voiceItem removeObserver:self forKeyPath:@"status"];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addObserver];
        //监听耳机/扬声器状态
        //        NSError *audioError = nil;
        //        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&audioError];
        
    }
    return self;
}

- (void)addObserver
{
    
    //监听耳机的插拔状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHeaderPhone) name:AVAudioSessionRouteChangeNotification object:nil];
    
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToRecordCate) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    
    
    
}
- (void)removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
}
//改变播放模式
- (void)checkHeaderPhone
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    for (AVAudioSessionPortDescription *dp in session.currentRoute.outputs) {
        if ([dp.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            break;
        } else {
            //设置为公放模式
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            break;
        }
    }
}

//设置成录播状态
- (void)switchToRecordCate
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
}
//播放
- (void)startPlayWithUrl:(NSString *)urlStr isLocalFile:(BOOL)isLocalFile
{
    if (self.isPlaying) {
        [self stopPlaying];
    }
    self.isLocalFile = isLocalFile;
    self.url = urlStr;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self checkHeaderPhone];
    
    //    NSError *error = [[NSError alloc] init];
    //新建item
    if (isLocalFile) {
        //本地文件
        NSURL *fileUrl = [NSURL fileURLWithPath:urlStr ? urlStr : @""];
        self.voiceItem = [[AVPlayerItem alloc] initWithURL:fileUrl];
        
    } else {
        
        self.voiceItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:urlStr]];
        
    }
    //    @weakify(self);
    //    [RACObserve(self.voiceItem, status) subscribeNext:^(id x) {
    //        @strongify(self);
    //    }];
    [self.player replaceCurrentItemWithPlayerItem:self.voiceItem];
    [self.voiceItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.player play];
    self.isPlaying = YES;
    
}

- (void)pause:(BOOL)pause
{
    if (pause) {
        [self.player pause];
        
    } else {
        [self.player play];
    }
    
}

- (void)stopPlaying
{
    if (!self.isPlaying) {
        return;
    }
    self.isPlaying = NO;
    [self.player replaceCurrentItemWithPlayerItem:nil];
    if (self.playComplete) {
        self.playComplete();
    }
    
}

- (void)voiceItemStateChange:(AVPlayerItemStatus)status
{
    switch (status) {
        case AVPlayerItemStatusReadyToPlay: {
            // 开始播放
            self.isPlaying = YES;
            if (self.startPlaying) {
                self.startPlaying(AVPlayerItemStatusReadyToPlay, self.voiceItem ? CMTimeGetSeconds(self.voiceItem.duration) :0);
            }
            
        } break;
            
        case AVPlayerItemStatusFailed: {
            NSLog(@"音频加载失败");
            
            self.isPlaying = NO;
            if (self.startPlaying) {
                self.startPlaying(AVPlayerItemStatusFailed, self.voiceItem ? CMTimeGetSeconds(self.voiceItem.duration) :0);
            }
        }
            break;
            
        case AVPlayerItemStatusUnknown: {
            NSLog(@"未知资源");
            self.isPlaying = NO;
            if (self.startPlaying) {
                self.startPlaying(AVPlayerItemStatusUnknown, self.voiceItem ? CMTimeGetSeconds(self.voiceItem.duration) :0);
            }
        }
            break;
            
        default:
            break;
            
    }
    
}

#pragma mark -setter and getter

- (AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        _player.volume = 1.0;
        __weak typeof(self) weakSelf = self;
        _observer =  [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
            if (weakSelf.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
                return ;
            }
            float current = CMTimeGetSeconds(time);
            //            float total = CMTimeGetSeconds(songItem.duration);
            if (weakSelf.playingBlock && weakSelf.isPlaying) {
                weakSelf.playingBlock(current);
            }
        }];
    }
    return _player;
}

- (NSUInteger)currentTime
{
    return self.audioPlayer.isPlaying ? self.audioPlayer.currentTime : 0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerItemStatus status = (AVPlayerItemStatus)[[change objectForKey:@"new"] integerValue];
        [self voiceItemStateChange:status];
        
    }
}
@end

