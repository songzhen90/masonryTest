//
//  SocketModel.h
//  HYOCR
//
//  Created by zhouyajie on 2018/6/29.
//  Copyright © 2018年 huayang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketModel : NSObject
@property (nonatomic, copy) NSString *head;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *lenByte;
@property (nonatomic, copy) NSString *md5;
@end
