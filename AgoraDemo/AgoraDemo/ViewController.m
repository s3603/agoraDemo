//
//  ViewController.m
//  AgoraDemo
//
//  Created by 林英彬 on 2018/3/22.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "ViewController.h"
#import "KeyCenter.h"
#import <AgoraSigKit/AgoraSigKit.h>

@interface ViewController ()
{
    AgoraAPI *signalEngine;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
