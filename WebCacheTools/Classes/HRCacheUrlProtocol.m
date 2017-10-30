//
//  HRCacheUrlProtocol.m
//  HoloRead
//
//  Created by 姚天成 on 2017/7/13.
//  Copyright © 2017年 姚天成. All rights reserved.
//

#import "HRCacheUrlProtocol.h"
#import "Reachability.h"
#import "NSString+HRHash.h"
#import "HRWebCacheModel.h"
#import "HRLoadHTMLCache.h"
#import "NSURLRequest+HRExtension.h"

#define NSLog(FORMAT, ...) fprintf(stderr,"[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

static NSString *HRCachingURLHeader = @"HRCacheURLProtocolCache";

static NSSet *HRCachingSupportedSchemes;

static NSString *const URLProtocolHandledKey = @"URLProtocolHandledKey";

static NSString *const CacheUrlStringKey = @"cacheUrlStringKey"; // 本地保存缓存urlKey的数组key

@interface HRCacheUrlProtocol()<NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

@property (nonatomic, strong) HRWebCacheModel *cacheModel;

@end

@implementation HRCacheUrlProtocol
- (HRWebCacheModel *)cacheModel
{
    if (!_cacheModel) {
        _cacheModel = [[HRWebCacheModel alloc] init];
    }
    return _cacheModel;
}

+ (void)initialize
{
    if (self == [HRCacheUrlProtocol class]){
        HRCachingSupportedSchemes = [NSSet setWithObjects:@"http", @"https", nil];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([HRCachingSupportedSchemes containsObject:[[request URL] scheme]] &&
        ([request valueForHTTPHeaderField:HRCachingURLHeader] == nil)){

        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    return mutableReqeust;
}

- (void)startLoading
{
    //防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:[[self request] mutableCopy]];
    
    // 加载缓存
    HRWebCacheModel *cacheModel = (HRWebCacheModel *)[[HRLoadHTMLCache defaultCache] objectForKey:[[[self.request URL] absoluteString] hr_md5String]];
    
    if ([self useCache] && cacheModel == nil) { // 可到达(有网)而且无缓存  才重新获取
        [self loadRequest];
    } else if(cacheModel) { // 有缓存
        [self loadCacheData:cacheModel];
    } else {
        NSLog(@"没网也没缓存,快开网");
    }
}

- (void)stopLoading
{
    [[self connection] cancel];
}

#pragma mark - NSURLConnectionDelegate
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest = [request mutableCopyWorkaround];
        [redirectableRequest setValue:nil forHTTPHeaderField:HRCachingURLHeader];
        
        [self cacheDataWithResponse:response redirectRequest:redirectableRequest];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    
    HRWebCacheModel *cacheModel = (HRWebCacheModel *)[[HRLoadHTMLCache defaultCache] objectForKey:[[[self.request URL] absoluteString] hr_md5String]];
    if (!cacheModel) {
        [self cacheDataWithResponse:self.response redirectRequest:nil];
    }
    
}

#pragma mark - private
/**
 *  存储缓存数据
 *  @param response              response
 *  @param redirectableRequest   重定向request
 */
- (void)cacheDataWithResponse:(NSURLResponse *)response  redirectRequest:(NSMutableURLRequest *)redirectableRequest
{
    [self.cacheModel setResponse:response];
    [self.cacheModel setData:[self data]];
    [self.cacheModel setRedirectRequest:redirectableRequest];
    
//    NSString *cacheStringkey = [[[self.request URL] absoluteString] hr_md5String];
//    if ([self.request.URL.lastPathComponent.pathExtension containsString:@"js"]) {
//        NSLog(@"%@不缓存",self.request.URL.lastPathComponent);
//        return;
//    }
//    [[HRLoadHTMLCache defaultCache] setObject:self.cacheModel forKey:cacheStringkey withBlock:^{
//        NSLog(@"新增缓存key=%@",[[self.request URL] absoluteString]);
//    }];
}

- (void)loadRequest
{
    NSMutableURLRequest *connectionRequest = [[self request] mutableCopyWorkaround];
    [connectionRequest setValue:@"" forHTTPHeaderField:HRCachingURLHeader];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest delegate:self];
    [self setConnection:connection];
}

- (BOOL)useCache
{
    BOOL reachable = (BOOL) [[Reachability reachabilityWithHostName:[[[self request] URL] host]] currentReachabilityStatus] != NotReachable;
    NSLog(@"网络是否可用 %d", reachable);
    return reachable;
}

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    } else {
        [[self data] appendData:newData];
    }
}

- (void)loadCacheData:(HRWebCacheModel *)cacheModel
{
    if (cacheModel) {
        NSData *data = [cacheModel data];
        NSURLResponse *response = [cacheModel response];
        NSURLRequest *redirectRequest = [cacheModel redirectRequest];
        
        if (redirectRequest) {
            [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
            NSLog(@"redirectRequest............. 重定向");
        } else {
            [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [[self client] URLProtocol:self didLoadData:data];
            [[self client] URLProtocolDidFinishLoading:self];
            NSLog(@"直接使用缓存.............缓存的url == %@ ", self.request.URL.absoluteString);
        }
    } else {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
    }
}

@end
