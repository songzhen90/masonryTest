//
//  HomeTestCell.m
//  HYOCR
//
//  Created by songzhen on 2018/7/4.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import "HomeTestCell.h"

@interface HomeTestCell()
@end
@implementation HomeTestCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *cellID = @"id";
    HomeTestCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[HomeTestCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.contentView.backgroundColor = [UIColor lightGrayColor];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
    }
    return self;
}
- (void)configViewCount:(NSInteger)count showInput:(BOOL)showInput
{
    
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [self.contentView layoutIfNeeded];
    
//    [self.contentView setNeedsLayout];
//    [self.contentView layoutIfNeeded];
    
    
    UILabel *header = [[UILabel alloc] init];
    header.text = @"第几场";
    header.backgroundColor = [UIColor yellowColor];
    header.textColor = [UIColor darkGrayColor];
    header.font = [UIFont systemFontOfSize:15.0f];
    [self.contentView addSubview:header];
    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(@0);
        make.top.mas_equalTo(@0);
        make.height.mas_equalTo(@40);
    }];
    
    UITextField *text = [[UITextField alloc] init];
    text.borderStyle = UITextBorderStyleRoundedRect;
    [self.contentView addSubview:text];
    [text mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(@20);
        make.right.mas_equalTo(@(-20));
        make.bottom.mas_equalTo(@(-10));
        if (showInput) {
            
            make.height.mas_equalTo(@40).priorityHigh();
        }else{
            make.height.mas_equalTo(@0).priorityHigh();
        }
        
    }];
    
    //九宫格布局
    //每行三个
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemW = (screenW - 4 * 20 ) / 3;
    UILabel *lastView;
    for (NSInteger index = 0; index < count; index++) {
        UILabel *view = [[UILabel alloc] init];
        view.text = @"hello word";
//        view.backgroundColor = [UIColor blueColor];
        [self.contentView addSubview:view];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            //设置高度
            make.height.mas_equalTo(@40);
            make.width.mas_equalTo(@(itemW));
            
            //计算距离顶部的公式 60 = 上一个距离顶部的高度 + UIlabel的高度
            float colTop = (20 + index/3 * 60.0f);

//            make.top.mas_equalTo(@(colTop));
            make.top.equalTo(header.mas_bottom).offset(colTop);
            
            //当是 左边一列的时候 都是 距离父视图 向左边 20的间隔
            if (index%3 == 0) {
                make.left.mas_equalTo(@20);
                                
            }else{
                //当时中间列的时候 在上一个UIlabel的右边 添加20个 距离 并且设置等高
                
                make.left.equalTo(lastView.mas_right).offset(20.0f);
                
            }
            
            if (index%3 == 2) {
                make.right.mas_equalTo(@(-20));
            }
            
            if (index == count - 1) {
                make.bottom.equalTo(text.mas_top).offset(0);
            }
            
        }];
        lastView = view;
    }
    
    
}



@end
