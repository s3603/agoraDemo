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
@property (weak, nonatomic) IBOutlet UIScrollView *bgScrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // please login
    [self performSelector:@selector(presentLogin) withObject:nil afterDelay:0.5];
    
    //
    self.bgScrollView.contentSize = CGSizeMake(320*2, 128);
    self.bgScrollView.pagingEnabled = YES;
//    UIView *
    //初始化我们需要改变背景色的UIView，并添加在视图上
    UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 275*2, 128)];
    [self.bgScrollView addSubview:theView];
    //初始化CAGradientlayer对象，使它的大小为UIView的大小
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = theView.bounds;
    //将CAGradientlayer对象添加在我们要设置背景色的视图的layer层
    [theView.layer addSublayer:gradientLayer];
    //设置渐变区域的起始和终止位置（范围为0-1）
    gradientLayer.startPoint = CGPointMake(0.4, 0);
    gradientLayer.endPoint = CGPointMake(0.6, 0);
    //设置颜色数组
    gradientLayer.colors = @[(__bridge id)[UIColor clearColor].CGColor,
                                  (__bridge id)[UIColor redColor].CGColor];
    //设置颜色分割点（范围：0-1）
    gradientLayer.locations = @[@(0.5f), @(1.0f)];
    
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
    if (!kLocalAccount) {
        [SVProgressHUD showInfoWithStatus:@"请先登录"];
        [self presentLogin];
        return;
    }
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
