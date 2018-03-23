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
    
    session.callStatus = RCCallDialing;
    [session inviteUsers:userIdList];

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
//            [weakSelf inviteUser:name];
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
