//
//  MessageInfoModel.m
//  VKOOY_iOS
//
//  Created by Mike on 18/8/14.
//  E-mail:vkooys@163.com
//  Copyright © 2015年 VKOOY. All rights reserved.
//

#import "MessageInfoModel.h"

@implementation MessageInfoModel

+ (NSDictionary *)objectClassInArray
{
    return @{@"replyList" : [CommentInfoModel class]};
}


@end

