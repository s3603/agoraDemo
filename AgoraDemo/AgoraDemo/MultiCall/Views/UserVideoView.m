//
//  UserVideoView.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/16.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "UserVideoView.h"

@interface UserVideoView()

@property (assign, nonatomic) NSUInteger uid;
@property (strong, nonatomic) UIImageView *micStateView;
@property (strong, nonatomic) UIView *speakingPoint;
@property (strong, nonatomic) UILabel *stateLab;

@end

@implementation UserVideoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithUid:(NSUInteger)uid
{
    self = [super init];
    
    self.uid = uid;
    NSString *name = [NSString stringWithFormat:@"%ld",uid];
    self.nameLab = [[UILabel alloc] init];
    int random = arc4random()%3;
    NSArray *colors = @[[UIColor redColor],[UIColor orangeColor],[UIColor purpleColor]];
    self.nameLab.backgroundColor = colors[random];
    self.nameLab.text = name;
    [self addSubview:self.nameLab];
    
    self.stateLab = [[UILabel alloc] init];
    self.stateLab.text = @"发起邀请";
    [self addSubview:self.stateLab];
    
    self.hostingView = [[UIView alloc] init];
    [self addSubview:self.hostingView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self addGestureRecognizer:tap];
    
    self.micStateView = [[UIImageView alloc] init];
    self.micStateView.image = [UIImage imageNamed:@"unmute"];
    [self addSubview:self.micStateView];
    
    self.speakingPoint = [[UIView alloc] init];
    self.speakingPoint.backgroundColor = [UIColor greenColor];
    self.speakingPoint.layer.cornerRadius = 7;
    self.speakingPoint.hidden = YES;
    [self addSubview:self.speakingPoint];

    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.stateLab.frame = CGRectMake(0, 0, self.frame.size.width, 20);
    self.nameLab.frame = CGRectMake(0, self.frame.size.height/2 - 10, self.frame.size.width, 20);
    self.hostingView.frame = self.bounds;
    self.micStateView.frame = CGRectMake(5, self.frame.size.height-30, 25, 25);
    self.speakingPoint.frame = CGRectMake(30, self.frame.size.height-25, 14, 14);
}

-(void)viewTapped
{
    if (self.tapBlock) {
        self.tapBlock(self.uid);
    }
}

-(void)changeMicMuteState:(BOOL)mute
{
    if (mute) {
        self.micStateView.image = [UIImage imageNamed:@"mute"];
        [self changeSpeakState:NO];
    }else{
        self.micStateView.image = [UIImage imageNamed:@"unmute"];
    }
}

-(void)changeSpeakState:(BOOL)isSpeaking
{
    [self.speakingPoint setHidden:!isSpeaking];
}

@end
