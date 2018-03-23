//
//  AppViewManager.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/20.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppViewManager : NSObject

+ (id)sharedManager;

- (void)presentVC:(UIViewController *)viewController;

@end
