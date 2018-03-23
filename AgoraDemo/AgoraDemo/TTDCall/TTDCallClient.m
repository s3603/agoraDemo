//
//  TTDCallClient.m
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "TTDCallClient.h"
#import "RCCallCommonDefine.h"
#import <AgoraSigKit/AgoraSigKit.h>
#import "AlertUtil.h"
#import "KeyCenter.h"
#import "MultiCallViewController.h"
#import "NSObject+JSONString.h"
#import "AppViewManager.h"

@interface TTDCallClient ()
{
    AgoraAPI *signalEngine;
}

@property (nonatomic, strong) NSMutableArray *callWindows;

@property (strong, nonatomic) NSMutableDictionary *remoteUserStatus;
@property (nonatomic, strong) NSString *channel;

@end

@implementation TTDCallClient

+(instancetype)sharedTTDCallClient {
    static TTDCallClient *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
        [instance loadSignalEngine];
        
    });
    return instance;
}

-(TTDCallSession *)startCall:(int)conversationType targetId:(NSString *)targetId to:(NSArray *)userIdList mediaType:(RCCallMediaType)type sessionDelegate:(id<RCCallSessionDelegate>)delegate extra:(NSString *)extra
{
    if (!self.account) {
        [AlertUtil showAlert:@"请先登录"];
        return nil;
    }
    
    TTDCallSession *session = [[TTDCallSession alloc] init];
    [session setDelegate:delegate];
    session.conversationType = conversationType;
    session.targetId = targetId;
    session.mediaType = type;
    session.extra = extra;
    session.inviter = self.account;
//    [session startCall];
    // 发起音视频邀请
    self.channel = @"999999";
    session.channel = self.channel;
    [session accept:0];
    
    // 查询用户在线状态，并发起 通话请求
    for (NSString *account in userIdList) {
        [signalEngine queryUserStatus:account];
    }
    session.callStatus = RCCallDialing;

    _currentCallSession = session;
    
    return self.currentCallSession;
}

-(TTDCallSession *)receiveCall:(NSString *)channel inviter:(NSString *)inviter to:(NSArray *)userIdList mediaType:(RCCallMediaType)type {
    TTDCallSession *session = [[TTDCallSession alloc] init];
    
    session.inviter = inviter;
    session.mediaType = type;
    session.channel = channel;
    
    session.callStatus = RCCallIncoming;
    _currentCallSession = session;
    return self.currentCallSession;
}

#pragma mark - 音视频Call IM消息处理
//-(void)receiveCallMessage:(RCMessage *)message
//{
//
//    RCDTestMessage *msg = (RCDTestMessage *)message.content;
//    // 被叫人 收到视频邀请
//    if ([msg.content isEqualToString:@"发起"]) {
//        TTDCallSession *session = [[TTDCallClient sharedTTDCallClient] receiveCall:ConversationType_PRIVATE targetId:message.senderUserId to:nil mediaType:RCCallMediaVideo];
//
//        RCCallSingleCallViewController *singleCallViewController = [[RCCallSingleCallViewController alloc] initWithIncomingCall:session];
//        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
//        if (vc) {
//            dispatch_sync_main_safe(^{
//                [vc presentViewController:singleCallViewController animated:YES completion:nil];
//            })
//        }
//        // 发出已经振铃消息
//        [self sendCallMessageWithKey:@"振铃" success:nil];
//    }
//
//    // 主叫人 收到被叫人已被振铃消息（在线）
//    if ([msg.content isEqualToString:@"振铃"]) {
//    }
//    // 被叫人 收到 主叫人取消
//    if ([msg.content isEqualToString:@"取消"]) {
//        [self.currentCallSession hangup];
//    }
//    // 主叫人 收到 被叫人接受
//    if ([msg.content isEqualToString:@"接受"]) {
//        if (self.currentCallSession.callStatus != RCCallActive) {
//            [self.currentCallSession accept:self.currentCallSession.mediaType];
//        }
//    }
//    // 主叫人 收到 被叫人拒绝
//    if ([msg.content isEqualToString:@"拒绝"]) {
//        [self.currentCallSession hangup];
//    }
//    // 双方 收到对方 挂断
//    if ([msg.content isEqualToString:@"挂断"]) {
//        [self.currentCallSession hangup];
//    }
//
//}

-(void)sendCallMessageWithKey:(NSString *)key success:(void (^)(long messageId))successBlock
{
//    RCDTestMessage *msg = [RCDTestMessage messageWithContent:key];
//    [[RCIMClient sharedRCIMClient] sendMessage:self.currentCallSession.conversationType targetId:self.currentCallSession.targetId content:msg pushContent:nil pushData:nil success:^(long messageId) {
//        if (successBlock) {
//            successBlock(messageId);
//        }
//    } error:^(RCErrorCode nErrorCode, long messageId) {
//        NSLog(@"发送失败。消息ID：%ld， 错误码：%ld", messageId, (long)nErrorCode);
//    }];
}

//MARK: - 邀请加入通话
- (void)inviteUser:(NSString *)name
{
    NSDictionary *extraDic = @{@"_require_peer_online": @(0)};
    [signalEngine channelInviteUser2:self.channel account:name extra:extraDic.JSONString];
}

//MARK: - AgoraAPI 监听
- (void)loadSignalEngine {
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];
    
    __weak typeof(self) weakSelf = self;
    
    signalEngine.onError = ^(NSString* name, AgoraEcode ecode, NSString* desc) {
        NSLog(@"onError, name: %@, code:%lu, desc: %@", name, (unsigned long)ecode, desc);
        if ([name isEqualToString:@"query_user_status"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AlertUtil showAlert:desc completion:^{
                }];
            });
        }
    };
    
    // 查询用户是否在线
    signalEngine.onQueryUserStatusResult = ^(NSString *name, NSString *status) {
        NSLog(@"onQueryUserStatusResult, name: %@, status: %@", name, status);
        if ([status intValue] == 0) {
            [weakSelf.remoteUserStatus setObject:@"0" forKey:@"name"];
        }
        else {
            //MARK: 用户在线 发起视频请求
            [weakSelf.remoteUserStatus setObject:@"1" forKey:@"name"];
            [weakSelf inviteUser:name];
        }
//        if (weakSelf.remoteUserStatus.count == weakSelf.remoteUserIdArray.count) {
//            [weakSelf alertUserStatus];
//        }
    };
    
    // 接到邀请
    signalEngine.onInviteReceived = ^(NSString *channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteReceived, channel: %@, account: %@, uid: %u", channelID, account, uid);
        if (!weakSelf.currentCallSession || weakSelf.currentCallSession.callStatus == RCCallHangup) {
            // 弹出接受呼叫VC
            MultiCallViewController *callVC = [[MultiCallViewController alloc] initWithNibName:@"MultiCallViewController" bundle:nil];
            [callVC showWithCall:[weakSelf receiveCall:channelID inviter:account to:nil mediaType:RCCallMediaVideo]];
        }else{
            
        }
    };
    
    // 远端 收到呼叫
    signalEngine.onInviteReceivedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid) {
        NSLog(@"onInviteReceivedByPeer, channel: %@, account: %@, uid: %u", channelID, account, uid);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        // 振铃
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf playRing:@"tones"];
        });
    };
    
    // 呼叫失败
    signalEngine.onInviteFailed = ^(NSString* channelID, NSString* account, uint32_t uid, AgoraEcode ecode, NSString *extra) {
        NSLog(@"Call %@ failed, ecode: %lu", account, (unsigned long)ecode);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
//        [self.currentCallSession ]
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            [weakSelf leaveChannel];
        //
        //            [AlertUtil showAlert:@"Call failed" completion:^{
        //                [weakSelf dismissViewControllerAnimated:NO completion:nil];
        //            }];
        //        });
    };
    
    // 远端接受呼叫
    signalEngine.onInviteAcceptedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteAcceptedByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
//            weakSelf.callingLabel.hidden = YES;
//            [weakSelf stopRing];
//            [weakSelf joinChannel];
        });
    };
    
    // 对方已拒绝呼叫
    signalEngine.onInviteRefusedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteRefusedByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSData *data = [extra dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([dic[@"status"] intValue] == 1) {
                NSString *message = [NSString stringWithFormat:@"%@ is busy", account];
                [AlertUtil showAlert:message completion:^{
                }];
            }
        });
    };
    
    // 对方已结束呼叫
    signalEngine.onInviteEndByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteEndByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        // 已取消呼叫？
    };
    
    // 接收点对点消息
    signalEngine.onMessageInstantReceive = ^(NSString *account, uint32_t uid, NSString *msg) {
        NSLog(@"onMessageInstantReceive, channel: %@, account: %@, uid: %u, msg: %@", @"", account, uid, msg);
    };
    
    // 接收频道消息
    signalEngine.onMessageChannelReceive = ^(NSString *channelID, NSString *account, uint32_t uid, NSString *msg) {
        NSLog(@"onMessageChannelReceive, channel: %@, account: %@, uid: %u, msg: %@", channelID, account, uid, msg);
    };
    
    signalEngine.onMessageSendError = ^(NSString *messageID, AgoraEcode ecode) {
        NSLog(@"onMessageSendError , messageID: %@ , code: %ld",messageID,ecode);
    };
}

-(void)loginWithAccount:(NSString *)account Success:(void(^)(uint32_t uid,int errorCode))success
{
    [signalEngine login:[KeyCenter appId]
                account:account
                  token:[KeyCenter generateSignalToken:account expiredTime:3600]
                    uid:0
               deviceID:nil];
    
    //MARK: 登录监听 onLoginSuccess
    signalEngine.onLoginSuccess = ^(uint32_t uid, int fd) {
        NSLog(@"Login successfully, uid: %u", uid);
//        _uid = uid;
        _account = account;
        success(uid,0);
    };
    
    signalEngine.onLoginFailed = ^(AgoraEcode ecode) {
        NSLog(@"Login failed, error: %lu", (unsigned long)ecode);
        success(0,ecode);
        dispatch_async(dispatch_get_main_queue(), ^{
            [AlertUtil showAlert:@"Login failed"];
        });
    };
}
@end
