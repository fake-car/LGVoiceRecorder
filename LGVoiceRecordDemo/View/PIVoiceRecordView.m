//
//  PIVoiceRecordView.m
//  Pinch
//
//  Created by li on 2018/3/13.
//  Copyright © 2018年 youweikeji. All rights reserved.
//

#import "PIVoiceRecordView.h"
#import "UIColor+Addition.h"
#import <Masonry.h>
#define line_width 3
#define PrimaryColor [UIColor colorWithHex:@"#836AFF"]
@interface RecordView ()
@property (nonatomic, strong) CAShapeLayer *aniLayer; //动画layer
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@end

@implementation RecordView

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self.layer addSublayer:[self layerWithLineColor:[UIColor colorWithHex:@"#F0F0F0"]]];
        //添加动画layer
        self.aniLayer = [self layerWithLineColor:[UIColor colorWithHex:@"#9681FC"]];
        self.aniLayer.hidden = YES;
        [self.layer addSublayer:self.aniLayer];
        CAShapeLayer *layer = (CAShapeLayer *)self.layer;
        layer = [self selfLayer:layer];
    }
    return self;
}

- (CAShapeLayer *)layerWithLineColor:(UIColor *)color
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    // 创建一个圆心为父视图中点的圆，
    CGRect rect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    layer.bounds = rect;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CGRectGetWidth(rect)/2];
    layer.lineWidth = line_width;
    layer.position = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor; // 填充色为透明（不设置为黑色）
    layer.strokeColor = color.CGColor; // 边框颜色
    layer.lineCap = kCALineCapRound; // 设置线为圆角
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    
    return layer;
}
- (CAShapeLayer *)selfLayer:(CAShapeLayer *)layer
{
    // 创建一个圆心为父视图中点的圆，
    CGRect rect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    layer.bounds = rect;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CGRectGetWidth(rect)/2];
    layer.lineWidth = 0.01;
    layer.position = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    
    layer.path = path.CGPath;
    layer.fillColor = [UIColor whiteColor].CGColor; // 填充色为透明（不设置为黑色）
    layer.strokeColor = [UIColor whiteColor].CGColor; // 边框颜色
    layer.lineCap = kCALineCapRound; // 设置线为圆角
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    
    return layer;
}

@end

@interface PIVoiceRecordView ()<CAAnimationDelegate>
@property (nonatomic, strong) RecordView *recordView;

//准备状态
@property (nonatomic, strong) UIView *readyView; //准备视图

//录制状态
@property (nonatomic, strong) UIView *recordingView; //录制视图
@property (nonatomic, strong) UILabel *recordTimeLabel; //时间标签

//播放状态
@property (nonatomic, strong) UIView *replayView; //播放视图
@property (nonatomic, strong) UILabel *pauseLabel; //暂停标签
@property (nonatomic, strong) UIButton *pauseBtn; //暂停/恢复按钮

//录制完成
@property (nonatomic, strong) UIView *finishView; //录制完成视图

@property (nonatomic, assign) NSInteger totalTime; //总时长
@property (nonatomic, strong) UILongPressGestureRecognizer *recordGes; //录音手势
@property (nonatomic, assign) CFTimeInterval pauseTime;
@end

@implementation PIVoiceRecordView

- (instancetype)initWithEnsureTitle:(NSString *)title frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.state = PIVoiceRecordViewStateReady;
        
        [self initViewsWithEnsureTitle:title];
        
        //添加声音状态视图
        [self initVoiceStateViews];
        
        //添加长按录音手势
        [self addLongPressRecordGes];
    }
    return self;
    
}


- (void)initViewsWithEnsureTitle:(NSString *)title
{
    
    //录音视图
    [self addSubview:self.recordView];
    
    [self.recordView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.centerX.equalTo(self);
        
        make.size.mas_equalTo(CGSizeMake(126 , 126 ));
    }];
    
    
    //重录
    UIButton *rerecordingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rerecordingBtn.backgroundColor = [UIColor whiteColor];
    rerecordingBtn.layer.cornerRadius = 67.0 /2  ;
    rerecordingBtn.layer.borderWidth = 1;
    rerecordingBtn.layer.borderColor = [UIColor colorWithHex:@"#999999"].CGColor;
    [rerecordingBtn setImage:[UIImage imageNamed:@"voice_rerecording_normal"] forState:UIControlStateNormal];
    [self addSubview:rerecordingBtn];
    
    [rerecordingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.recordView.mas_left).offset(-30 );
        make.centerY.equalTo(self.recordView);
        make.size.mas_equalTo(CGSizeMake(67  , 67 ));
    }];
    
    @weakify(self);
    [[rerecordingBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        //重新录制
        [self reRecording];
    }];
    
    //重录标签
    UILabel *reLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    reLabel.text = @"重录";
    reLabel.textColor = [UIColor colorWithHex:@"#999999"];
    reLabel.textAlignment = NSTextAlignmentCenter;
    reLabel.font = [UIFont systemFontOfSize:12.0 ];
    [self addSubview:reLabel];
    
    [reLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(rerecordingBtn);
        make.top.equalTo(rerecordingBtn.mas_bottom).offset(12 );
        make.height.mas_equalTo(17 );
    }];
    
    
    
    //下一步
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.backgroundColor = [UIColor whiteColor];
    nextBtn.layer.cornerRadius = rerecordingBtn.layer.cornerRadius;
    nextBtn.layer.borderWidth = 1;
    nextBtn.layer.borderColor = rerecordingBtn.layer.borderColor;
    [nextBtn setImage:[UIImage imageNamed:@"voice_save_normal"] forState:UIControlStateNormal];
    [self addSubview:nextBtn];
    
    [nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.recordView.mas_right).offset(30 );
        make.centerY.equalTo(self.recordView);
        make.size.mas_equalTo(CGSizeMake(67 , 67 ));
    }];
    
    [[nextBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self finishRecording];
    }];
    
    //下一步
    UILabel *nextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    nextLabel.text = title;
    nextLabel.textAlignment = reLabel.textAlignment;
    nextLabel.font = reLabel.font;
    nextLabel.textColor = reLabel.textColor;
    [self addSubview:nextLabel];
    
    [nextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(nextBtn);
        make.top.equalTo(reLabel);
        make.height.mas_equalTo(17 );
    }];
    
    [RACObserve(self, state) subscribeNext:^(id x) {
        @strongify(self);
        
        if (self.state == PIVoiceRecordViewStateFinish) {
            //录音完成
            [rerecordingBtn setImage:[UIImage imageNamed:@"voice_rerecording_highlight"] forState:UIControlStateNormal];
            [nextBtn setImage:[UIImage imageNamed:@"voice_save_highlight"] forState:UIControlStateNormal];
            rerecordingBtn.layer.borderColor = PrimaryColor.CGColor;
            nextBtn.layer.borderColor = rerecordingBtn.layer.borderColor;
            reLabel.textColor = PrimaryColor;
            nextLabel.textColor = reLabel.textColor;
        } else if (self.state == PIVoiceRecordViewStateReady) {
            //录音未完成
            [rerecordingBtn setImage:[UIImage imageNamed:@"voice_rerecording_normal"] forState:UIControlStateNormal];
            [nextBtn setImage:[UIImage imageNamed:@"voice_save_normal"] forState:UIControlStateNormal];
            rerecordingBtn.layer.borderColor = [UIColor colorWithHex:@"#999999"].CGColor;
            nextBtn.layer.borderColor = rerecordingBtn.layer.borderColor;
            reLabel.textColor = [UIColor colorWithHex:@"#999999"];
            nextLabel.textColor = reLabel.textColor;
            
        }
    }];
}

- (void)initVoiceStateViews
{
    
    //准备视图
    self.readyView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.recordView addSubview:self.readyView];
    
    [self.readyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.recordView);
    }];
    
    
    //录音键
    UIImageView *recordImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    recordImgView.image = [UIImage imageNamed:@"voice_mic"];
    [self.readyView addSubview:recordImgView];
    
    [recordImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.readyView);
        make.top.equalTo(self.readyView).offset(29 );
        make.size.mas_equalTo(CGSizeMake(55 , 55 ));
    }];
    
    //录音标签
    UILabel *recordLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    recordLabel.text = @"按住录音";
    recordLabel.textAlignment = NSTextAlignmentCenter;
    recordLabel.font = [UIFont systemFontOfSize:12.0 ];
    recordLabel.textColor = PrimaryColor;
    [self.readyView addSubview:recordLabel];
    [recordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(recordImgView.mas_bottom).offset(2.0 );
        make.left.right.equalTo(recordImgView);
        make.height.mas_equalTo(17.0 );
    }];
    
    
    //时间标签
    self.recordTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.recordTimeLabel.hidden = YES;
    self.recordTimeLabel.textColor = PrimaryColor;
    self.recordTimeLabel.font = [UIFont systemFontOfSize:19.0 ];
    self.recordTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.recordTimeLabel];
    
    [self.recordTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.recordView);
        make.bottom.equalTo(self.recordView.mas_top).offset(-6 );
        make.height.mas_equalTo(25 );
    }];
    
    /***************************************/
    //播放状态
    
    //播放视图
    self.replayView = [[UIView alloc] initWithFrame:CGRectZero];
    self.replayView.hidden = YES;
    [self.recordView addSubview:self.replayView];
    [self.replayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(self.recordView);
    }];
    
    //暂停/恢复按钮
    self.pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.pauseBtn setImage:[UIImage imageNamed:@"voice_pause"] forState:UIControlStateNormal];
    [self.pauseBtn setImage:[UIImage imageNamed:@"voice_replay"] forState:UIControlStateSelected];
    [self.replayView addSubview:self.pauseBtn];
    
    [self.pauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.replayView).offset(39 );
        make.centerX.equalTo(self.replayView);
        make.size.mas_equalTo(CGSizeMake(42 , 42 ));
    }];
    
    @weakify(self);
    [[self.pauseBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self pause:!self.pauseBtn.selected];
    }];
    
    
    //暂停标签
    UILabel *pauseLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    pauseLabel.text = @"暂停";
    pauseLabel.textColor = PrimaryColor;
    pauseLabel.font = [UIFont systemFontOfSize:12 ];
    pauseLabel.textAlignment = NSTextAlignmentCenter;
    [self.replayView addSubview:pauseLabel];
    
    [pauseLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.replayView).offset(10 );
        make.right.equalTo(self.replayView).offset(-10 );
        make.top.equalTo(self.pauseBtn.mas_bottom).offset(1 );
    }];
    
    self.pauseLabel = pauseLabel;
    
    /*************************/
    
    //录制完成
    
    //录制完成视图
    
    self.finishView = [[UIView alloc] initWithFrame:CGRectZero];
    self.finishView.hidden = YES;
    [self.recordView addSubview:self.finishView];
    
    [self.finishView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(self.recordView);
    }];
    
    
    UIButton *replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [replayBtn setImage:[UIImage imageNamed:@"voice_replay"] forState:UIControlStateNormal];
    
    [replayBtn setAdjustsImageWhenHighlighted:NO];
    [self.finishView addSubview:replayBtn];
    
    [replayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.finishView).offset(38 );
        make.centerX.equalTo(self.finishView);
        make.size.equalTo(self.pauseBtn);
    }];
    
    [[replayBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self replay];
    }];
    
    //播放标签
    UILabel *replayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    replayLabel.text = @"播放";
    replayLabel.font = pauseLabel.font;
    replayLabel.textColor = PrimaryColor;
    replayLabel.textAlignment = NSTextAlignmentCenter;
    [self.finishView addSubview:replayLabel];
    
    [replayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(replayBtn.mas_bottom).offset(1 );
        make.left.equalTo(self.finishView).offset(10 );
        make.right.equalTo(self.finishView).offset(-10 );
        
    }];
}

- (void)addLongPressRecordGes
{
    //添加长按增加手势
    self.recordGes = [[UILongPressGestureRecognizer alloc] init];
    
    self.recordGes.minimumPressDuration=0.1f;//定义按的时间
    
    @weakify(self);
    [[self.recordGes rac_gestureSignal] subscribeNext:^(id x) {
        @strongify(self);
        UILongPressGestureRecognizer *press = x;
        [self longPressAction:press];
    }];
    [self.recordView addGestureRecognizer:self.recordGes];
}

- (void)updateState:(PIVoiceRecordViewState)state seconds:(NSUInteger)seconds{
    NSLog(@"%ld, %ld",self.totalTime,seconds);
    if (_state != state) {
        self.state = state;
        //更换UI
        
        switch (self.state) {
            case PIVoiceRecordViewStateReady: {
                //准备录制
                [self layerHidden:YES];
                self.recordTimeLabel.hidden = YES;
                
                self.recordGes.enabled = YES;
                self.readyView.hidden = NO;
                self.recordingView.hidden = YES;
                self.replayView.hidden = YES;
                self.finishView.hidden = YES;
                
            }
                break;
            case PIVoiceRecordViewStateRecording: {
                self.recordTimeLabel.text = @"0S";
                self.recordTimeLabel.hidden = NO;
                self.recordGes.enabled = YES;
                self.readyView.hidden = YES;
                self.recordingView.hidden = NO;
                self.replayView.hidden = YES;
                self.finishView.hidden = YES;
                
            }
                break;
                
            case PIVoiceRecordViewStateReplaying: {
                //                [self layerHidden:NO];
                self.recordTimeLabel.text = [NSString stringWithFormat:@"%lds",self.totalTime];
                self.recordTimeLabel.hidden = NO;
                self.pauseLabel.text = @"暂停";
                self.pauseBtn.selected = NO;
                self.recordGes.enabled = NO;
                self.readyView.hidden = YES;
                self.recordingView.hidden = YES;
                self.replayView.hidden = NO;
                self.finishView.hidden = YES;
                
            }
                break;
                
            case PIVoiceRecordViewStateFinish: {
                self.recordTimeLabel.hidden = NO;
                [self layerHidden:NO];
                self.recordGes.enabled = NO;
                self.readyView.hidden = YES;
                self.recordingView.hidden = YES;
                self.replayView.hidden = YES;
                self.finishView.hidden = NO;
                
            }
                break;
            default:
                break;
        }
    }
    
    
    switch (self.state) {
        case PIVoiceRecordViewStateReady: {
            //准备录制
            
        }
            break;
        case PIVoiceRecordViewStateRecording: {
            //录制中
            self.recordTimeLabel.text = [NSString stringWithFormat:@"%ldS",MIN(seconds, MAXRECORDTIME)];
        }
            break;
            
        case PIVoiceRecordViewStateReplaying: {
            self.recordTimeLabel.text = [NSString stringWithFormat:@"%lds",MAX(0, self.totalTime - seconds)];
        }
            break;
            
        case PIVoiceRecordViewStateFinish: {
            if (seconds > 0) {
                self.totalTime = seconds;
                self.recordTimeLabel.text = [NSString stringWithFormat:@"%lds",seconds];
            }
            
        }
            break;
        default:
            break;
    }
    
}

#pragma mark -event response
//长按手势
- (void)longPressAction:(UILongPressGestureRecognizer *)press
{
    if (press.state == UIGestureRecognizerStateChanged) {
        //判断区域
        CGPoint point = [press locationInView:self];
        if (!CGRectContainsPoint(self.recordView.frame, point)) {
            press.enabled = NO;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(voiceRecordViewRecordAction:)]) {
        if (press.state == UIGestureRecognizerStateEnded | press.state == UIGestureRecognizerStateFailed | press.state == UIGestureRecognizerStateCancelled) {
            [self.delegate voiceRecordViewRecordAction:NO];
        } else if (press.state == UIGestureRecognizerStateBegan) {
            [self.delegate voiceRecordViewRecordAction:YES];
            
            
        }
    }
    
}

//重新录制
- (void)reRecording
{
    if ([self.delegate respondsToSelector:@selector(voiceRecordViewStartReRecording)]) {
        [self.delegate voiceRecordViewStartReRecording];
    }
}

//录制完成
- (void)finishRecording
{
    if ([self.delegate respondsToSelector:@selector(voiceRecordViewFinishRecording)]) {
        [self.delegate voiceRecordViewFinishRecording];
    }
}

//播放
- (void)replay
{
    if ([self.delegate respondsToSelector:@selector(voiceRecordViewStartReplaying)]) {
        [self.delegate voiceRecordViewStartReplaying];
    }
}

//暂停播放
- (void)pause:(BOOL)pause
{
    self.pauseBtn.selected = pause;
    if (pause) {
        self.pauseLabel.text = @"播放";
        [self pauseAnimation:self.recordView.aniLayer];
    } else {
        self.pauseLabel.text = @"暂停";
        [self resumeAnimation:self.recordView.aniLayer];
    }
    if ([self.delegate respondsToSelector:@selector(voiceRecordViewPause:)]) {
        [self.delegate voiceRecordViewPause:pause];
    }
}
- (void)pauseAnimation:(CALayer *)layer {
    
    //1.取出当前时间，转成动画暂停的时间
    
    CFTimeInterval pauseTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    
    //2.设置动画的时间偏移量，指定时间偏移量的目的是让动画定格在该时间点的位置
    
    layer.timeOffset = pauseTime;
    
    //3.将动画的运行速度设置为0， 默认的运行速度是1.0
    
    layer.speed = 0;
    
}
- (void)resumeAnimation:(CALayer *)layer
{
    //1.将动画的时间偏移量作为暂停的时间点
    
    CFTimeInterval pauseTime = layer.timeOffset;
    
    //2.计算出开始时间
    
    CFTimeInterval begin = CACurrentMediaTime() - pauseTime;
    
    [layer setTimeOffset:0];
    
    [layer setBeginTime:begin];
    
    layer.speed = 1;
}
#pragma mark -animation

- (void)startRecordingAnimation
{

    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        CABasicAnimation *bas=[CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        bas.duration= MAXRECORDTIME;//动画时间
        bas.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        bas.fromValue=[NSNumber numberWithInteger:0];
        bas.toValue=[NSNumber numberWithInteger:1];
        [self.recordView.aniLayer addAnimation:bas forKey:@"recordAni"];
        
        [self layerHidden:NO];
        self.recordView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.recordView.bgLayer.lineWidth = 3;
        
    }];
    
    
}
- (void)stopRecordingAnimation
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.recordView.aniLayer removeAllAnimations];
        //关闭隐式动画
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.recordView.aniLayer.strokeStart = 0;
        self.recordView.aniLayer.strokeEnd = 1;
        [CATransaction commit];
        self.recordView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:nil];
    
}
- (void)startReplayingAnimation:(CGFloat)voiceDuration
{
    
    //    [self layerHidden:NO];
    if (voiceDuration == 0 || isnan(voiceDuration)) {
        return;
    }
    if ([self.recordView.aniLayer animationForKey:@"replayAni"]) {
        return;
    }
    CABasicAnimation *bas=[CABasicAnimation animationWithKeyPath:@"strokeStart"];
    bas.duration= voiceDuration;//动画时间
    bas.delegate = self;
    bas.fromValue=[NSNumber numberWithInteger:0];
    bas.toValue=[NSNumber numberWithInteger:1];
    bas.removedOnCompletion = NO;
    bas.fillMode = kCAFillModeForwards;
    [self.recordView.aniLayer addAnimation:bas forKey:@"replayAni"];

    
}
- (void)stopReplayingAnimation
{
    if (![self.recordView.aniLayer animationForKey:@"replayAni"]) {
        return;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.recordView.aniLayer.timeOffset = 0;
    self.recordView.aniLayer.speed = 1;
    self.recordView.aniLayer.beginTime = CACurrentMediaTime();
    self.recordView.aniLayer.strokeStart = 0;
    self.recordView.aniLayer.strokeEnd = 1;
    [CATransaction commit];
    
    [self.recordView.aniLayer removeAnimationForKey:@"replayAni"];
    
    
}

- (void)layerHidden:(BOOL)hidden
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.recordView.aniLayer.hidden = hidden;
    [CATransaction commit];
    
}
#pragma mark -CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag) {
        [self layerHidden:YES];
    }
    
}

#pragma mark -setter and getter
- (UIView *)recordView
{
    if (!_recordView) {
        _recordView = [[RecordView alloc] initWithFrame:CGRectMake(0, 0, 126 , 126 )];
        //        _recordView.backgroundColor = WhiteColor;
        _recordView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }
    return _recordView;
}

@end
