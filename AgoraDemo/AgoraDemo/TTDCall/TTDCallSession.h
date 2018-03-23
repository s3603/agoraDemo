//
//  TTDCallSession.h
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCCallCommonDefine.h"
#import <UIKit/UIKit.h>
#import "VideoSession.h"

#define MAIN_WINDOW [[[UIApplication sharedApplication] delegate] window]

/*!
 通话状态变化的监听器
 */
@protocol RCCallSessionDelegate <NSObject>

@optional

- (void)updateInterface:(NSArray<VideoSession *> *)videoSessions;

/*!
 通话已接通
 */
- (void)callDidConnect;

/*!
 通话已结束
 */
- (void)callDidDisconnect;

/*!
 对端用户正在振铃
 
 @param userId 用户ID
 */
- (void)remoteUserDidRing:(NSString *)userId;

/*!
 有用户被邀请加入通话
 
 @param userId    被邀请的用户ID
 @param mediaType 希望被邀请者使用的媒体类型
 */
- (void)remoteUserDidInvite:(NSString *)userId mediaType:(RCCallMediaType)mediaType;

/*!
 对端用户加入了通话
 
 @param userId    用户ID
 @param mediaType 用户的媒体类型
 */
- (void)remoteUserDidJoin:(NSString *)userId mediaType:(RCCallMediaType)mediaType;

/*!
 对端用户切换了媒体类型
 
 @param userId    用户ID
 @param mediaType 切换至的媒体类型
 */
- (void)remoteUserDidChangeMediaType:(NSString *)userId mediaType:(RCCallMediaType)mediaType;

/*!
 对端用户开启或关闭了摄像头的状态
 
 @param disabled  是否关闭摄像头
 @param userId    用户ID
 */
- (void)remoteUserDidDisableCamera:(BOOL)disabled byUser:(NSString *)userId;

/*!
 对端用户挂断
 
 @param userId 用户ID
 @param reason 挂断的原因
 */
- (void)remoteUserDidLeft:(NSString *)userId reason:(RCCallDisconnectReason)reason;

/*!
 彩铃
 */
- (void)shouldAlertForWaitingRemoteResponse;

/*!
 来电铃声
 */
- (void)shouldRingForIncomingCall;

/*!
 停止播放铃声(通话接通或挂断)
 */
- (void)shouldStopAlertAndRing;

/*!
 通话过程中的错误回调
 
 @param error 错误码
 
 @warning
 这个接口回调的错误码主要是为了提供必要的log以及提示用户，如果是不可恢复的错误，SDK会挂断电话并回调callDidDisconnect，App可以在callDidDisconnect中统一处理通话结束的逻辑。
 */
- (void)errorDidOccur:(RCCallErrorCode)error;

/*!
 当前通话网络状态的回调，该回调方法每两秒触发一次
 
 @param txQuality   上行网络质量
 @param rxQuality   下行网络质量
 */
- (void)networkTxQuality:(RCCallQuality)txQuality rxQuality:(RCCallQuality)rxQuality;

@end


/**
 通话实体
 */
@interface TTDCallSession : NSObject


/*!
 通话的会话类型
 */
@property(nonatomic, assign) int conversationType;

/*!
 通话频道
 */
@property(nonatomic, strong) NSString *channel;

/*!
 通话的目标会话ID
 */
@property(nonatomic, strong) NSString *targetId;

/*!
 是否是多方通话
 */
@property(nonatomic, assign, getter=isMultiCall) BOOL multiCall;

/*!
 通话的扩展信息
 */
@property(nonatomic, strong) NSString *extra;

/*!
 通话的当前状态
 */
@property(nonatomic, assign) RCCallStatus callStatus;

/*!
 当前用户使用的媒体类型
 */
@property(nonatomic, assign) RCCallMediaType mediaType;


/*!
 通话的最初发起人
 */
@property(nonatomic, strong) NSString *caller;

/*!
 邀请当前用户加入通话的邀请者
 */
@property(nonatomic, strong) NSString *inviter;

/*!
 通话接通时间
 */
@property(nonatomic, assign) long long connectedTime;

/*!
 通话挂断原因
 */
@property(nonatomic, assign) RCCallDisconnectReason disconnectReason;

/*!
 设置通话状态变化的监听器
 
 @param delegate 通话状态变化的监听器
 */
- (void)setDelegate:(id<RCCallSessionDelegate>)delegate;

/*!
 接听来电
 
 @param type 接听使用的媒体类型
 */
- (void)accept:(RCCallMediaType)type;

/*!
 挂断通话
 */
- (void)hangup;

/*!
 设置用户所在的视频View
 
 @param userId 用户ID（自己或他人）
 @param view   视频的View
 */
- (void)setVideoView:(UIView *)view userId:(int)userId;

/*!
 更换自己使用的媒体类型
 
 @param type 媒体类型
 */
- (BOOL)changeMediaType:(RCCallMediaType)type;

/*!
 静音状态
 */
@property(nonatomic, readonly) BOOL isMuted;

/*!
 设置静音状态
 
 @param muted 是否静音
 
 @return 是否设置成功
 
 @discussion 默认值为NO。
 */
- (BOOL)setMuted:(BOOL)muted;

/*!
 扬声器状态，是否开启扬声器
 
 @discussion 音频通话的默认值为NO，视频通话的默认值为YES。
 */
@property(nonatomic, readonly) BOOL speakerEnabled;

/*!
 设置扬声器状态
 
 @param speakerEnabled  是否开启扬声器
 @return                是否设置成功
 */
- (BOOL)setSpeakerEnabled:(BOOL)speakerEnabled;

/*!
 摄像头状态，是否开启摄像头
 */
@property(nonatomic, readonly) BOOL cameraEnabled;

/*!
 设置摄像头状态
 
 @param cameraEnabled  是否开启摄像头
 @return               是否设置成功
 
 @discussion 音频通话的默认值为NO，视频通话的默认值为YES。
 */
- (BOOL)setCameraEnabled:(BOOL)cameraEnabled;

/*!
 切换前后摄像头
 
 @return 是否切换成功
 */
- (BOOL)switchCameraMode;


/**
 发送命令消息

 @param key CMDKey
 @param uid 对方id
 */
-(void)sendCMDMessage:(NSString *)key To:(NSUInteger)uid;

-(void)inviteUsers:(NSArray *)userIdArray;

@end
