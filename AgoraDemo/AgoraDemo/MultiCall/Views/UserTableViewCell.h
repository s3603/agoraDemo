//
//  UserTableViewCell.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/19.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLab,*desLab;
@property (weak, nonatomic) IBOutlet UIButton *selectedBtn;

@end
