//
//  MultiCallViewController.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTDCallSession.h"

@interface MultiCallViewController : UIViewController

/*!
 通话实体
 */
@property(nonatomic, strong) TTDCallSession *callSession;

- (void)startCallTo:(NSArray *)userIdList;
- (void)showWithCall:(TTDCallSession *)callSession;

@end
