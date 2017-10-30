//
//  HRWebCacheModel.h
//  HoloRead
//
//  Created by 姚天成 on 2017/7/13.
//  Copyright © 2017年 姚天成. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HRWebCacheModel : NSObject<NSCoding>

@property (nonatomic ,strong) NSData *data;
@property (nonatomic ,strong) NSURLResponse *response;
@property (nonatomic ,strong) NSURLRequest *redirectRequest;

@end
