//
//  HRLoadHTMLCache.m
//  HoloRead
//
//  Created by 姚天成 on 2017/7/13.
//  Copyright © 2017年 姚天成. All rights reserved.
//

#import "HRLoadHTMLCache.h"

static NSString *const cacheName = @"HRWebLoanHTMLString";

@implementation HRLoadHTMLCache

+ (instancetype)defaultCache
{
    static HRLoadHTMLCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[HRLoadHTMLCache alloc] initWithName:cacheName];
        [cache.diskCache setCountLimit:1000];
        [cache.diskCache setAutoTrimInterval:60];
        cache.diskCache.errorLogsEnabled = true;
    });
    return cache;
}

@end
