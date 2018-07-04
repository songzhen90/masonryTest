//
//  TicketModel.h
//  HYOCR
//
//  Created by songzhen on 2018/7/3.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TicketModel : NSObject

//倍数
@property (nonatomic, strong) NSNumber *appNumbers;
//子玩法
@property (nonatomic, strong) NSNumber *childType;
//票号
@property (nonatomic, copy) NSString *id;
//期号
@property (nonatomic, copy) NSString *issue;
//投注内容(209^180625-033(3_4.15,1_3.45,0_1.59))
@property (nonatomic, copy) NSString *lotteryCode;
//彩票ID
@property (nonatomic, copy) NSString *lotteryId;
//彩票金额(分)
@property (nonatomic, strong) NSNumber *lotteryValue;
//销售方式
@property (nonatomic, strong) NSNumber *saleType;


@end
