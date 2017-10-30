#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HRCacheUrlProtocol.h"
#import "HRLoadHTMLCache.h"
#import "HRWebCacheModel.h"
#import "HRWebCacheTools.h"
#import "NSURLRequest+HRExtension.h"
#import "Reachability.h"

FOUNDATION_EXPORT double WebCacheToolsVersionNumber;
FOUNDATION_EXPORT const unsigned char WebCacheToolsVersionString[];

