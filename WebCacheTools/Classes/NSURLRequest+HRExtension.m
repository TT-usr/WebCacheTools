//
//  NSURLProtocol+HRExtension.m
//  HoloRead
//
//  Created by 姚天成 on 2017/7/13.
//  Copyright © 2017年 姚天成. All rights reserved.
//

#import "NSURLRequest+HRExtension.h"

@implementation NSURLRequest (HRExtension)
- (id) mutableCopyWorkaround
{
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    if ([self HTTPBodyStream]) {
        [mutableURLRequest setHTTPBodyStream:[self HTTPBodyStream]];
    } else {
        [mutableURLRequest setHTTPBody:[self HTTPBody]];
    }
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];
    
    return mutableURLRequest;
}

@end
