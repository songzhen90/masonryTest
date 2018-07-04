//
//  ViewController.m
//  HYOCR
//
//  Created by zhouyajie on 2018/6/28.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import "HomeViewController.h"
#import "GCDAsyncSocket.h"
#import <objc/runtime.h>
#import <AipOcrSdk/AipOcrSdk.h>
#import "MyMD5.h"
#import "CommonCrypto/CommonDigest.h"
#import "ScanResultViewController.h"
#import "JSONKit.h"
#import "TicketModel.h"
#import "HomeTestCell.h"


typedef void(^successHandler)(id result);
typedef void(^failHandler)(NSError *error);

@interface HomeViewController ()<GCDAsyncSocketDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) GCDAsyncSocket *serviceSocket;
@property (nonatomic, strong) NSTimer *heartTimer;//心跳定时器


//扫描相关
@property (nonatomic, strong) UIViewController *scanVC;
@property (nonatomic, copy) successHandler success;
@property (nonatomic, copy) failHandler fail;

//票据信息
@property (nonatomic, strong) TicketModel *ticket;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation HomeViewController
{
    BOOL show;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self creatUI];
//    [self configCallback];
//
//    NSString *licenseFile = [[NSBundle mainBundle] pathForResource:@"aip" ofType:@"license"];
//    NSData *licenseFileData = [NSData dataWithContentsOfFile:licenseFile];
//    if(!licenseFileData) {
//        [[[UIAlertView alloc] initWithTitle:@"授权失败" message:@"授权文件不存在" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
//    }
//    [[AipOcrService shardService] authWithLicenseFileData:licenseFileData];
//    [self socketConnectHost];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(@0);
        make.bottom.mas_equalTo(@(-50));
    }];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"刷新" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.mas_equalTo(@0);
        make.height.mas_equalTo(@40);
    }];

}
- (void)refresh
{
    show = !show;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeTestCell *cell = [HomeTestCell cellWithTableView:tableView];
    [cell configViewCount:10 showInput:show];
    return cell;
}


- (void)creatUI {
    UIButton *getTicketBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    getTicketBtn.frame = CGRectMake(100, 100, 100, 100);
    getTicketBtn.backgroundColor = [UIColor blueColor];
    [getTicketBtn setTitle:@"开始接票" forState:UIControlStateNormal];
    [getTicketBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [getTicketBtn addTarget:self action:@selector(getTicket) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *scanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [scanBtn setTitle:@"扫描票据" forState:UIControlStateNormal];
    scanBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
    [scanBtn addTarget:self action:@selector(scan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanBtn];
    [scanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(@20);
        make.left.mas_equalTo(@20);
        make.right.mas_equalTo(@(-20));
        make.height.mas_equalTo(@45);
    }];

    [self.view addSubview:getTicketBtn];
    
    
    UIButton *stopTicketBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    stopTicketBtn.frame = CGRectMake(100, 200, 100, 100);
    stopTicketBtn.backgroundColor = [UIColor blueColor];
    [stopTicketBtn setTitle:@"取消接票" forState:UIControlStateNormal];
    [stopTicketBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [stopTicketBtn addTarget:self action:@selector(stopTicket) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopTicketBtn];
}


- (void)scan
{
    __weak typeof(self) weakSelf = self;
    _scanVC = [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true",@"classify_dimension": @"lottery"};
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.scanVC.view animated:YES];
        hud.label.text = @"识别中";
        [[AipOcrService shardService] detectTextAccurateBasicFromImage:image
                                                           withOptions:options
                                                        successHandler:weakSelf.success
                                                           failHandler:weakSelf.fail];
    }];
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:_scanVC animated:YES completion:nil];
}
- (void)configCallback
{
    [MBProgressHUD hideHUDForView:_scanVC.view animated:YES];
    __weak typeof(self) weakSelf = self;
    _success = ^(id result){
        NSLog(@"result = %@", result);
        NSMutableString *message = [NSMutableString string];
        if ([result[@"words_result"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary * obj in result[@"words_result"]) {
                if ([obj isKindOfClass:[NSDictionary class]] &&obj[@"words"]) {
                    if ([obj[@"words"] isKindOfClass:[NSString class]] && ![obj[@"words"] containsString:@"*"]) {
                        [message appendFormat:@"%@\n", obj[@"words"]];
                    }
                }else{
                    [message appendFormat:@"%@\n", obj];
                }
            }
        }else{
            [message appendFormat:@"%@", result];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakSelf.scanVC dismissViewControllerAnimated:NO completion:^{
                ScanResultViewController *svc = [[ScanResultViewController alloc] init];
                UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:svc];
                svc.scanResult = message;
                [weakSelf presentViewController:nvc animated:YES completion:nil];
            }];
        }];
    };
    
    
    
    _fail = ^(NSError *error){
        [MBProgressHUD hideHUDForView:weakSelf.scanVC.view animated:YES];
    };
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)socketConnectHost{
    NSLog(@"连接服务器");
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    [_socket connectToHost:@"192.168.1.250" onPort:2211 withTimeout:20 error:&error];
}

// socket成功连接回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"成功连接到%@:%d",host,port);
    //    _bufferData = [[NSMutableData alloc] init]; // 存储接收数据的缓存区
    [self startLogin];//登录命令，测试账号13800002222 密码123
    [self.socket readDataWithTimeout:-1 tag:0];
    
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    Byte *receiveArr = (Byte *)[data bytes];

    if (receiveArr[0] == 0x20) {//登录
        if (receiveArr[1] == 0x00) {//连接成功
            //心跳包
            [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] run];
        }else if (receiveArr[1] == 0x02) {//验证md5校验错误
            
        }else if (receiveArr[1] == 0x03) {//连接失败无此设备
            
        }
    }else if (receiveArr[0] == 0x21) {//心跳
        NSLog(@"心跳回复");
    }else if (receiveArr[0] == 0x22) {//收票状态
        NSLog(@"收票状态回复%@", data);
    }else if (receiveArr[0] == 0x3a){//收票
        NSLog(@"收票");
        NSData *ticketData = [data subdataWithRange:NSMakeRange(5, data.length - 5 - 16 - 2)];
        id ticketInfo = [NSJSONSerialization JSONObjectWithData:ticketData options:NSJSONReadingMutableContainers error:nil];
        if (ticketInfo && [ticketInfo isKindOfClass:[NSDictionary class]]) {
            NSLog(@"ticketInfo = %@", ticketInfo);
            self.ticket = [TicketModel yy_modelWithJSON:ticketInfo];
            [self receiveTicketFeedback];
        }
    }
    //持续接收服务端的数据
    [sock readDataWithTimeout:-1 tag:tag];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {

    
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"断开连接");
    
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {

}

#pragma -mark 登录
- (void)startLogin {
    
    //计算数据所占字节
    NSData *data = [[NSString stringWithFormat:@"type:11\nimei:%@\nid:%@\nislogin:0\npwd:%@",@"123456",@"13800002222",@"123"] dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger intLength = [data length];
    unsigned char byte1 = (intLength & 0xff00) >> 8;
    unsigned char byte2 = (intLength & 0xff);
    int highDataLength = [[NSString stringWithFormat:@"%d",byte1] intValue] == 0 ? 00 : [[NSString stringWithFormat:@"%d",byte1] intValue];
    int lowDataLength = [[NSString stringWithFormat:@"%d",byte2] intValue];
    Byte byte[] = {16,00,17,highDataLength,lowDataLength};
    
    
    //数据的byte
    Byte *dataByte = (Byte *)[data bytes];
    
    //    数据+MD5的byte
    NSData *md5Data = [[NSString stringWithFormat:@"type:11\nimei:%@\nid:%@\nislogin:0\npwd:%@",@"123456",@"13800002222",@"123"] dataUsingEncoding:NSUTF8StringEncoding];
    Byte *md5byte = (Byte *)[md5Data bytes];
    
    NSData *md5TokenData = [@"e10adc3949ba59abbe56e057f20f883e" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *md5TokenByte = (Byte *)[md5TokenData bytes];
    
    //md5校验位
    Byte md5Byte[5 + md5Data.length + md5TokenData.length];
    for (int i = 0; i < 5+md5Data.length + md5TokenData.length; i++) {
        if (i <= 4) {
            md5Byte[i] = byte[i];
        }else if (i<=4+md5Data.length){
            md5Byte[i] = md5byte[i - 5];
        }else {
            md5Byte[i] = md5TokenByte[i - 5 - md5Data.length];
        }
    }
    
    //md5加密后byte
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(md5Byte, (unsigned int)(5+md5Data.length + md5TokenData.length), result);
    
    ///r/n
    NSData *endData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *endByte = (Byte *)[endData bytes];
    
    Byte allByte[5 + [data length] + 16 + [endData length]];
    for (int i = 0; i < 5 + [data length] + 16 + [endData length]; i++) {
        if (i <= 4) {
            allByte[i] = byte[i];
        }else if (i <= 4 + [data length]) {
            allByte[i] = dataByte[i - 5];
        }else if (i <= 4 + [data length] + 16 ) {
            allByte[i] = result[i - 5 - [data length]];
        }else {
            allByte[i] = endByte[i - 5 - [data length] - 16];
        }
    }
    
    NSData *totalData = [[NSData alloc] initWithBytes:allByte length:sizeof(allByte)];
    [self.socket writeData:totalData withTimeout:-1 tag:100];
    [self.socket readDataWithTimeout:-1 tag:200];
    
}


#pragma -mark 心跳
- (void)heartBeat {
    Byte headerByte[] ={17,00,16,00,00};
    
    NSString *temStr = @"9658299e48c15f9eaaa2352fe3b36f17";
    NSData *temData = [temStr dataUsingEncoding:NSUTF8StringEncoding];
    Byte *Tembytes = (Byte *)[temData bytes];
   
    NSData *endData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *endByte = (Byte *)[endData bytes];
    
    Byte heartByte[5 + temData.length + endData.length];
    for (int i = 0; i < 5+temData.length+endData.length; i++) {
        if (i <= 4) {
            heartByte[i] = headerByte[i];
        }else if (i <= 4 + temData.length) {
            heartByte[i] = Tembytes[i - 5];
        }else {
            heartByte[i] = endByte[i - 5 - temData.length];
        }
    }
    
    NSData *totalData = [[NSData alloc] initWithBytes:heartByte length:sizeof(heartByte)];
    [self.socket writeData:totalData withTimeout:-1 tag:1];
}


#pragma -mark 收票状态
- (void)getTicket {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:true],@"isopen", nil];
    NSData *data = [[dic Jsonkit_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger intLength = [data length];
    unsigned char byte1 = (intLength & 0xff00) >> 8;
    unsigned char byte2 = (intLength & 0xff);
    int highDataLength = [[NSString stringWithFormat:@"%d",byte1] intValue] == 0 ? 00 : [[NSString stringWithFormat:@"%d",byte1] intValue];
    int lowDataLength = [[NSString stringWithFormat:@"%d",byte2] intValue];
    Byte headerByte[] ={18,00,18,highDataLength,lowDataLength};
    
    //数据
    Byte *dataByte = (Byte *)[data bytes];
    
    //token
    NSData *md5TokenData = [@"e10adc3949ba59abbe56e057f20f883e" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *md5TokenByte = (Byte *)[md5TokenData bytes];
    
    //md5校验位
    Byte md5Byte[5 + data.length+ md5TokenData.length];
    for (int i = 0; i < 5+data.length + md5TokenData.length; i++) {
        if (i <= 4) {
            md5Byte[i] = headerByte[i];
        }else if (i<=4+data.length){
            md5Byte[i] = dataByte[i - 5];
        }else {
            md5Byte[i] = md5TokenByte[i - 5 - data.length];
        }
    }

    //md5加密后byte
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(md5Byte, (unsigned int)(5+data.length + md5TokenData.length), result);

    ///r/n
    NSData *endData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *endByte = (Byte *)[endData bytes];
    
    Byte allByte[5 + [data length] + 16 + [endData length]];
    for (int i = 0; i < 5 + [data length] + 16 + [endData length]; i++) {
        if (i <= 4) {
            allByte[i] = headerByte[i];
        }else if (i <= 4 + [data length]) {
            allByte[i] = dataByte[i - 5];
        }else if (i <= 4 + [data length] + 16 ) {
            allByte[i] = result[i - 5 - [data length]];
        }else {
            allByte[i] = endByte[i - 5 - [data length] - 16];
        }
    }

    NSData *totalData = [[NSData alloc] initWithBytes:allByte length:sizeof(allByte)];
    [self.socket writeData:totalData withTimeout:-1 tag:100];
    [self.socket readDataWithTimeout:-1 tag:200];
}

- (void)stopTicket {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],@"isopen", nil];
    NSData *data = [[dic Jsonkit_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger intLength = [data length];
    unsigned char byte1 = (intLength & 0xff00) >> 8;
    unsigned char byte2 = (intLength & 0xff);
    int highDataLength = [[NSString stringWithFormat:@"%d",byte1] intValue] == 0 ? 00 : [[NSString stringWithFormat:@"%d",byte1] intValue];
    int lowDataLength = [[NSString stringWithFormat:@"%d",byte2] intValue];
    Byte headerByte[] ={18,00,18,highDataLength,lowDataLength};
    
    //数据
    Byte *dataByte = (Byte *)[data bytes];
    
    //token
    NSData *md5TokenData = [@"e10adc3949ba59abbe56e057f20f883e" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *md5TokenByte = (Byte *)[md5TokenData bytes];
    
    //md5校验位
    Byte md5Byte[5 + data.length+ md5TokenData.length];
    for (int i = 0; i < 5+data.length + md5TokenData.length; i++) {
        if (i <= 4) {
            md5Byte[i] = headerByte[i];
        }else if (i<=4+data.length){
            md5Byte[i] = dataByte[i - 5];
        }else {
            md5Byte[i] = md5TokenByte[i - 5 - data.length];
        }
    }
    
    //md5加密后byte
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(md5Byte, (unsigned int)(5+data.length + md5TokenData.length), result);
    
    ///r/n
    NSData *endData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *endByte = (Byte *)[endData bytes];
    
    Byte allByte[5 + [data length] + 16 + [endData length]];
    for (int i = 0; i < 5 + [data length] + 16 + [endData length]; i++) {
        if (i <= 4) {
            allByte[i] = headerByte[i];
        }else if (i <= 4 + [data length]) {
            allByte[i] = dataByte[i - 5];
        }else if (i <= 4 + [data length] + 16 ) {
            allByte[i] = result[i - 5 - [data length]];
        }else {
            allByte[i] = endByte[i - 5 - [data length] - 16];
        }
    }
    
    NSData *totalData = [[NSData alloc] initWithBytes:allByte length:sizeof(allByte)];
    [self.socket writeData:totalData withTimeout:-1 tag:100];
    [self.socket readDataWithTimeout:-1 tag:200];
}

/**
 收到票回馈
 */
- (void)receiveTicketFeedback
{
    NSMutableData *newTotalData = [[NSMutableData alloc] init];

    Byte headerByte[5] = {0x4a, 0x00, 0x11, 00, 00};
    [newTotalData appendBytes:headerByte length:sizeof(headerByte)];
    
    //token
    NSData *md5TokenData = [@"e10adc3949ba59abbe56e057f20f883e" dataUsingEncoding:NSUTF8StringEncoding];
    Byte *md5TokenByte = (Byte *)[md5TokenData bytes];
    
    //md5校验位
    Byte md5Byte[5 + md5TokenData.length];
    for (int i = 0; i < 5 + md5TokenData.length; i++) {
        if (i <= 4) {
            md5Byte[i] = headerByte[i];
        }else {
            md5Byte[i] = md5TokenByte[i - 5];
        }
    }

    //md5加密后byte
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(md5Byte, (unsigned int)(5 + md5TokenData.length), result);
    [newTotalData appendBytes:result length:sizeof(result)];
    
    ///r/n
    NSData *endData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    [newTotalData appendData:endData];
    
    [self.socket writeData:newTotalData withTimeout:-1 tag:100];
    [self.socket readDataWithTimeout:-1 tag:200];
}

@end
