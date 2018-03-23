//
//  SelectedUserViewController.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/19.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "SelectedUserViewController.h"
#import "UserTableViewCell.h"
#import <AgoraSigKit/AgoraSigKit.h>
#import "KeyCenter.h"

@interface SelectedUserViewController () <UITableViewDelegate,UITableViewDataSource>
{
    AgoraAPI *signalEngine;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *userArr;

@end

@implementation SelectedUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:@"UserCell"];
    

    self.userArr = [NSMutableArray new];
    for (int i=0; i<5; i++) {
//        NSString *account = [NSString stringWithFormat:@"%ld",(long)[button tag]];
        User *user = [User new];
        user.uid = 10000+i;
        user.account = [NSString stringWithFormat:@"%ld",user.uid];
        [self.userArr addObject:user];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];
    
    __weak typeof(self) weakSelf = self;
    [signalEngine setOnQueryUserStatusResult:^(NSString *name, NSString *status) {
        NSLog(@"onQueryUserStatusResult, name: %@, status: %@", name, status);
        User *user = [weakSelf userWithAccount:name];
        user.isOnline = [status intValue] > 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSInteger index = [weakSelf.userArr indexOfObject:user];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];
    [signalEngine setOnChannelQueryUserIsIn:^(NSString *channelID, NSString *account, int isIn) {
        NSLog(@"OnChannelQueryUserIsIn, account: %@, isIn: %d %@", account, isIn,channelID);
        User *user = [weakSelf userWithAccount:account];
        if (isIn) {
            user.channelId = channelID;
        }else{
            user.channelId = nil;
        }
    }];
    [signalEngine setOnChannelQueryUserNumResult:^(NSString *channelID, AgoraEcode ecode, int num) {
        NSLog(@"setOnChannelQueryUserNumResult, channelID: %@, num: %d", channelID, num);
    }];
    
    for (User *user in self.userArr) {
        if (self.channelId) {
            [signalEngine channelQueryUserIsIn:self.channelId account:user.account];
        }
        [signalEngine queryUserStatus:user.account];
    }
    [signalEngine channelQueryUserNum:self.channelId];
}

-(User *)userWithAccount:(NSString *)account
{
    for (User *user in self.userArr) {
        if ([user.account isEqualToString:account]){
            return user;
        }
    }
    return nil;
}

-(IBAction)commit:(id)sender
{
    NSMutableArray *array = [NSMutableArray new];
    for (User *user in self.userArr) {
        if (user.isSelected && !user.channelId){
            NSLog(@"邀请 %@ 加入 %@",user.account, self.channelId);
            [array addObject:user.account];
        }
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.commitBlock) {
            self.commitBlock(array);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//MARK: - tableView delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.userArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    User *user = self.userArr[indexPath.row];
    
    cell.nameLab.text = [NSString stringWithFormat:@"%ld",user.uid];
    if (!user.isOnline) {
        cell.desLab.text = @"不在线";
        cell.selectedBtn.enabled = YES;
    }else{
        if (user.channelId) {
            cell.desLab.text = [NSString stringWithFormat:@"已加入频道"];
            cell.selectedBtn.enabled = NO;
        }else{
            cell.desLab.text = @"可邀请";
            cell.selectedBtn.enabled = YES;
        }
    }
    cell.selectedBtn.selected = user.isSelected;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = self.userArr[indexPath.row];
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (!user.channelId) {
        user.isSelected = !user.isSelected;
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.selectedBtn.selected = user.isSelected;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

@end

//MARK: - User Model
@implementation User

@end
