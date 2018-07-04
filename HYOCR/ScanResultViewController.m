//
//  ScanResultViewController.m
//  HYOCR
//
//  Created by yyj on 2018/7/2.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import "ScanResultViewController.h"

@interface ScanResultViewController ()

@end

@implementation ScanResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"扫描结果显示";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.00];
    
    [self setupNavbar];
    [self setupViews];
}

- (void)setupNavbar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
}
- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupViews
{
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(@0);
        make.bottom.mas_equalTo(@0);
    }];
    
    
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.00];
    label.textColor = [UIColor darkTextColor];
    label.font = [UIFont systemFontOfSize:16.0f];
    label.numberOfLines = 0;
    label.text = self.scanResult;
    [scrollView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(@20);
        make.right.equalTo(self.view).offset(-20);
        make.top.mas_equalTo(@20);
    }];
    
    [scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(label.mas_bottom);
    }];
}


@end
