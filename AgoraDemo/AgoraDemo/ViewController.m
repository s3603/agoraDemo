//
//  ViewController.m
//  AgoraDemo
//
//  Created by 林英彬 on 2018/3/22.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "ViewController.h"
#import "TTDCallClient.h"
#import "SelectedUserViewController.h"
#import "MultiCallViewController.h"

@interface ViewController ()
{
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // please login
    [self performSelector:@selector(presentLogin) withObject:nil afterDelay:0.5];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)presentLogin
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"请您登录" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i=0; i<5; i++) {
        NSString *account = [NSString stringWithFormat:@"%d",i+10000];
        UIAlertAction *user1 = [UIAlertAction actionWithTitle:account style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self loginWithAccount:account];
        }];
        [sheet addAction:user1];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [sheet addAction:cancel];
    [sheet popoverPresentationController].permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:sheet animated:YES completion:nil];
}

-(void)loginWithAccount:(NSString *)account
{
    [[TTDCallClient sharedTTDCallClient] loginWithAccount:account Success:^(uint32_t uid, int errorCode) {
        if (!errorCode) {
            [SVProgressHUD showSuccessWithStatus:@"登录成功"];
            dispatch_async_main_safe((^{
                self.userLab.text = [NSString stringWithFormat:@"当前登录：%@",account];
            }));
        }
    }];
}

-(IBAction)pushInviteUserVC:(id)sender
{
    SelectedUserViewController *selectUserVC = [[SelectedUserViewController alloc] initWithNibName:@"SelectedUserViewController" bundle:nil];
    [self presentViewController:selectUserVC animated:YES completion:nil];
    [selectUserVC setCommitBlock:^(NSArray *userIdArray) {
        dispatch_async_main_safe(^{
            MultiCallViewController *callVC = [[MultiCallViewController alloc] initWithNibName:@"MultiCallViewController" bundle:nil];
            [callVC startCallTo:userIdArray];
        });
    }];
}

@end
