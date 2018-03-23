//
//  TTDCallSession.m
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "TTDCallSession.h"
#import "KeyCenter.h"
#import "TTDCallClient.h"
#import "VideoSession.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <AgoraSigKit/AgoraSigKit.h>
#import "AlertUtil.h"
#import "NSObject+JSONString.h"
#import "UIView+Toast.h"

@interface TTDCallSession () <AgoraRtcEngineDelegate>
{
    AgoraRtcEngineKit *mediaEngine;
    AgoraAPI *signalEngine;
}

@property (weak, nonatomic) id<RCCallSessionDelegate> sessionDelegate;
@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *fullSession;

@end

@implementation TTDCallSession

-(instancetype)init
{
    self = [super init];
    self.videoSessions = [NSMutableArray new];
    [self initAgoraSDK];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    return self;
}

- (void)applicationWillTerminate:(NSNotification *)noti
{
    [self hangup];
}

-(void)initAgoraSDK
{
    mediaEngine = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter appId] delegate:self];
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd ah-mm-ss"];
    NSString *logFilePath = [NSString stringWithFormat:@"%@/AgoraRtcEngine %@.log",
                             NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES).firstObject,
                             [dateFormatter stringFromDate:[NSDate date]]];
    [mediaEngine setLogFile:logFilePath];
    //[mediaEngine setParameters:@"{\"rtc.log_filter\":65535}"];
    
    [mediaEngine setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [mediaEngine setClientRole:AgoraClientRoleBroadcaster];
    [mediaEngine setVideoProfile:AgoraVideoProfileLandscape240P swapWidthAndHeight:NO];
    [mediaEngine enableAudioVolumeIndication:500 smooth:3];
    [mediaEngine enableVideo];
    [self startLocalVideo];
}

-(void)setDelegate:(id<RCCallSessionDelegate>)delegate
{
    self.sessionDelegate = delegate;
}

-(void)accept:(RCCallMediaType)type
{
    [self joinCall];
}

-(void)joinCall
{
    // 接受邀请
    [signalEngine channelInviteAccept:self.channel account:self.inviter uid:0];
    
    int uid = [TTDCallClient sharedTTDCallClient].account.intValue;
    NSString *key = [KeyCenter generateMediaKey:self.channel uid:0 expiredTime:0];
    // 加入 media频道
    int result = [mediaEngine joinChannelByToken:key channelId:self.channel info:nil uid:uid joinSuccess:nil];
    if (result != AgoraEcode_SUCCESS) {
        NSLog(@"Join channel failed: %d", result);
        // 加入失败
        [signalEngine channelInviteEnd:self.channel account:self.inviter uid:0];
        
        __weak typeof(self) weakSelf = self;
        [AlertUtil showAlert:[NSString stringWithFormat:@"Join channel failed"] completion:^{
//            [weakSelf dismissViewControllerAnimated:NO completion:nil];
        }];
    }else{
        // 加入成功监听频道信息
        [self addSignalEngineListener];
        // 加入 信令频道
        [signalEngine channelJoin:self.channel];
        [_sessionDelegate updateInterface:self.videoSessions];
        [_sessionDelegate callDidConnect];
    }
}

-(void)hangup
{
    [self leaveChannel];
}

-(BOOL)changeMediaType:(RCCallMediaType)type
{
    if (type == RCCallMediaAudio) {
        [mediaEngine enableVideo];
    }else{
        [mediaEngine disableVideo];
    }
    return YES;
}

-(void)setVideoView:(UIView *)view userId:(int)userId
{
    int loginUserId = [TTDCallClient sharedTTDCallClient].account.intValue;
    
    if (view) {
        if (loginUserId == userId) {
            VideoSession *localSession = [VideoSession localSession];
            localSession.canvas.view = view;
            [mediaEngine setupLocalVideo:localSession.canvas];
        }else{
            VideoSession *userSession = [self videoSessionOfUid:userId];
            userSession.canvas.view = view;
            [mediaEngine setupRemoteVideo:userSession.canvas];
        }
    }else{
        if (loginUserId == userId) {
            [mediaEngine setupLocalVideo:nil];
        }else{
            [mediaEngine setupRemoteVideo:nil];
        }
    }
}

-(BOOL)switchCameraMode
{
    return [mediaEngine switchCamera];
}

-(BOOL)setMuted:(BOOL)muted
{
    [mediaEngine muteLocalAudioStream:muted];
//    [mediaEngine muteLocalVideoStream:muted];
    return YES;
}

-(BOOL)setCameraEnabled:(BOOL)cameraEnabled
{
    return [mediaEngine muteLocalVideoStream:cameraEnabled];
}

-(BOOL)setSpeakerEnabled:(BOOL)speakerEnabled
{
    return [mediaEngine setEnableSpeakerphone:speakerEnabled];
}

- (void)leaveChannel {
    
    [mediaEngine stopPreview];
    [mediaEngine setupLocalVideo:nil];
    if (self.callStatus == RCCallActive || self.callStatus == RCCallDialing) {
    }
    // 挂断
    [mediaEngine leaveChannel:nil];
    // 离开信令频道
    [signalEngine channelLeave:self.channel];
    
    if (self.callStatus == RCCallDialing) {
//        for (NSString *account in self.remoteUserIdArray) {
//            [signalEngine channelInviteEnd:self.channel account:account uid:0];
//        }
    }
    self.callStatus = RCCallHangup;
//    [_sessionDelegate callDidDisconnect];
}

//MARK: -  AgoraAPI Listener
-(void)addSignalEngineListener
{
    [signalEngine setOnChannelJoined:^(NSString *channelID) {
        // 加入成功
        NSLog(@"Join 信令 channel : %@", channelID);
    }];
    [signalEngine setOnChannelJoinFailed:^(NSString *channelID, AgoraEcode ecode) {
        // 音视频加入成功， 信令加入失败， 重连机制
        NSLog(@"Join 信令 channel failed : %lu", (unsigned long)ecode);
    }];
    [signalEngine setOnMessageChannelReceive:^(NSString *channelID, NSString *account, uint32_t uid, NSString *msg) {
        NSLog(@"onMessageChannelReceive, channel: %@, account: %@, uid: %u, msg: %@", channelID, account, uid, msg);
        // 接到消息，判断是否命令自己
        if ([channelID isEqualToString:self.channel]) {
            NSDictionary *params = [msg JSONValue];
            if ([[TTDCallClient sharedTTDCallClient].account isEqualToString:params[@"to"]] && [params[@"show"] intValue] == 0) {
                TTDCMDMessageType type = [CMDKeys indexOfObject:params[@"cmd"]];
                NSString *showMessage = @"";
                if (type == MESSAGE_KICK) {
                    [mediaEngine pauseAudioMixing];
                    showMessage = [NSString stringWithFormat:@"您已被 %@ 踢出聊天",params[@"from"]];
                    [AlertUtil showAlert:showMessage completion:^{
                        [_sessionDelegate callDidDisconnect];
                    }];
                }else
                if (type == MESSAGE_CLOSE_MIC) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 关闭麦克风",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_sessionDelegate ]
//                        weakSelf.micButton.selected = YES;
//                        [mediaEngine muteLocalAudioStream:weakSelf.micButton];
                    });
                }else
                if (type == MESSAGE_OPEN_VIDEO) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 打开摄像头",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
                    [mediaEngine enableVideo];
                }else
                if (type == MESSAGE_CLOSE_VIDEO) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 关闭摄像头",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
                    [mediaEngine disableVideo];
                }else
                if (type == MESSAGE_OPEN_MIC) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 打开麦克风",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        weakSelf.micButton.selected = NO;
//                        [mediaEngine muteLocalAudioStream:weakSelf.micButton];
//                    });
                }else
                if (type == MESSAGE_AUDIENCE) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 设置为观众",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
                    int success = [mediaEngine setClientRole:AgoraClientRoleAudience];
                    NSLog(@"%i",success);
                }else
                if (type == MESSAGE_PLAYER) {
                    showMessage = [NSString stringWithFormat:@"您被%@ 设置为播放端",params[@"from"]];
                    [AlertUtil showAlert:showMessage];
                    int success = [mediaEngine setClientRole:AgoraClientRoleBroadcaster];
                    NSLog(@"%i",success);
                }
                [self sendCMDExecuteMessage:params ShowText:showMessage];

            }else{
                // 执行人是其他人 显示show==1 的提示信息
                if ([params[@"show"] intValue] == 1) {
//                    [AlertUtil showAlert:];
                    [MAIN_WINDOW makeToast:params[@"showText"]];
                }
            }
        }
    }];
    [signalEngine setOnMessageSendSuccess:^(NSString *messageID) {
        NSLog(@"发送消息成功 %@", messageID);
    }];
    [signalEngine setOnMessageSendError:^(NSString *messageID, AgoraEcode ecode) {
        NSLog(@"发送消息 %@ failed : %lu", messageID, (unsigned long)ecode);
    }];
}

//MARK: sendChannelMessage
-(void)sendCMDMessage:(NSString *)key To:(NSUInteger)uid
{
    NSString *to = [NSString stringWithFormat:@"%ld",uid];

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:key forKey:@"cmd"];
    [params setObject:to forKey:@"to"];
    [params setObject:[TTDCallClient sharedTTDCallClient].account forKey:@"from"];
    [params setObject:@0 forKey:@"show"];

    [signalEngine messageChannelSend:self.channel msg:[params JSONString] msgID:nil];
}
-(void)sendCMDExecuteMessage:(NSDictionary *)params ShowText:(NSString *)showText
{
    showText = [showText stringByReplacingOccurrencesOfString:@"您" withString:[NSString stringWithFormat:@"%@ ",[TTDCallClient sharedTTDCallClient].account]];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic setValue:@1 forKey:@"show"];
    [dic setValue:showText forKey:@"showText"];
    [signalEngine messageChannelSend:self.channel msg:[dic JSONString] msgID:nil];
}

//MARK: - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"rtcEngine:didOccurWarning: %ld", (long)warningCode);
    static int count = 0;
    if (warningCode == 104) {
        count ++;
    }
    if (count == 10) {
//        [self leaveChannel];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"rtcEngine:didOccurError: %ld", (long)errorCode);
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didLeaveChannelWithStats:(AgoraChannelStats *)stats
{
    NSLog(@"rtcEngine:didLeaveChannelWithStats: %ld", (long)stats);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        [self.sessionDelegate updateInterface:self.videoSessions];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    NSLog(@"rtcEngine:didJoinChannel: %@", channel);
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"rtcEngine:didJoinedOfUid: %ld", (long)uid);
    VideoSession *userSession = [self videoSessionOfUid:uid];
    [mediaEngine setupRemoteVideo:userSession.canvas];
    [_sessionDelegate remoteUserDidJoin:[NSString stringWithFormat:@"%ld",uid] mediaType:RCCallMediaVideo];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    NSLog(@"rtcEngine:didOfflineOfUid: %ld", (long)uid);
    // only receive this callback if remote user logout unexpected
    //    [self leaveChannel];
    //    [self dismissViewControllerAnimated:NO completion:nil];
    VideoSession *deleteSession;
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            deleteSession = session;
        }
    }
    
    if (deleteSession) {
        [self.videoSessions removeObject:deleteSession];
        [deleteSession.userView removeFromSuperview];
        [self.sessionDelegate updateInterface:self.videoSessions];

        if (deleteSession == self.fullSession) {
            self.fullSession = nil;
        }
    }
    [_sessionDelegate remoteUserDidLeft:[NSString stringWithFormat:@"%ld",uid] reason:RCCallDisconnectReasonRemoteHangup];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
    didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    [fetchedSession.userView changeMicMuteState:muted];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
  didVideoEnabled:(BOOL)enabled byUid:(NSUInteger)uid
{
    [_sessionDelegate remoteUserDidDisableCamera:!enabled byUser:[NSString stringWithFormat:@"%ld",uid]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:
(NSArray*)speakers totalVolume:(NSInteger)totalVolume
{
    for (AgoraRtcAudioVolumeInfo *info in speakers) {
//        NSLog(@"reportAudioVolumeIndicationOfSpeakers： \n uid: %ld 音量: %ld",info.uid,info.volume);
    }
    
    for (VideoSession *session in self.videoSessions) {
        BOOL speaking = NO;
        for (AgoraRtcAudioVolumeInfo *info in speakers) {
            if (info.uid == session.uid) {
                if (info.volume > 15) {
                    speaking = YES;
                    // 正在发言
                    [session.userView changeSpeakState:YES];
                }
            }
        }
        if(!speaking) {
            // 未发言
            [session.userView changeSpeakState:NO];
        }
    }
}

-(void)rtcEngineVideoDidStop:(AgoraRtcEngineKit *)engine
{
    NSLog(@"rtcEngineVideoDidStop");
}

//MARK: - VideoSession
- (VideoSession *)fetchSessionOfUid:(NSUInteger)uid {
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)videoSessionOfUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    if (fetchedSession) {
        return fetchedSession;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [self.videoSessions addObject:newSession];
        [self.sessionDelegate updateInterface:self.videoSessions];
        return newSession;
    }
}

- (void)startLocalVideo {
    int loginUserId = [TTDCallClient sharedTTDCallClient].account.intValue;
    VideoSession *localSession = [[VideoSession alloc] initWithUid:loginUserId];
    [self.videoSessions addObject:localSession];
    
    [mediaEngine startPreview];
    [mediaEngine setupLocalVideo:localSession.canvas];
}

@end