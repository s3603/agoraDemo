//
//  VideoSession.h
//  OpenLive
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import "UserVideoView.h"

@interface VideoSession : NSObject
@property (assign, nonatomic) NSUInteger uid;
@property (strong, nonatomic) AgoraRtcVideoCanvas *canvas;
@property (strong, nonatomic) UserVideoView *userView;

- (instancetype)initWithUid:(NSUInteger)uid;
+ (instancetype)localSession;

@end
