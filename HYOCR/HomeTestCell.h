//
//  HomeTestCell.h
//  HYOCR
//
//  Created by songzhen on 2018/7/4.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeTestCell : UITableViewCell
+ (instancetype)cellWithTableView:(UITableView *)tableView;
- (void)configViewCount:(NSInteger)count showInput:(BOOL)showInput;
@end
