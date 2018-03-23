//
//  SelectedUserViewController.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/19.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectedUserViewController : UIViewController

@property (copy, nonatomic) NSString *channelId;
@property (copy, nonatomic) void (^commitBlock)(NSArray *userIdArray) ;

@end

@interface User : NSObject

@property (assign, nonatomic) NSUInteger uid;
@property (assign, nonatomic) BOOL isOnline,isSelected;
@property (copy, nonatomic) NSString *channelId,*account;

@end
