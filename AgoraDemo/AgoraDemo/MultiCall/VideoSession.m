//
//  VideoSession.m
//  OpenLive
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "VideoSession.h"

@implementation VideoSession
- (instancetype)initWithUid:(NSUInteger)uid {
    if (self = [super init]) {
        self.uid = uid;
        
        self.userView = [[UserVideoView alloc] initWithUid:uid];
        self.userView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.canvas = [[AgoraRtcVideoCanvas alloc] init];
        self.canvas.uid = uid;
        self.canvas.view = self.userView.hostingView;
        self.canvas.renderMode = AgoraVideoRenderModeHidden;
    }
    return self;
}

+ (instancetype)localSession {
    return [[VideoSession alloc] initWithUid:0];
}
@end
