//
//  BSGURLSessionTracingDelegate.m
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import "BSGURLSessionTracingDelegate.h"

#import <Bugsnag/Bugsnag.h>


@implementation BSGURLSessionTracingDelegate

// All proxies should be talking to the same sink.
static id<BSGBreadcrumbSink> g_sink;

+ (BSGURLSessionTracingDelegate *_Nonnull)sharedDelegate {
    static dispatch_once_t onceToken;
    static BSGURLSessionTracingDelegate *delegate;
    dispatch_once(&onceToken, ^{
        delegate = [BSGURLSessionTracingDelegate new];
    });

    return delegate;
}

+ (void)setSink:(nullable id<BSGBreadcrumbSink>) sink {
    g_sink = sink;
}

- (BOOL)canTrace {
    return g_sink != nil;
}

+ (nonnull NSString *)messageForResponse:(NSHTTPURLResponse *)response {
    if (response) {
        if (100 <= response.statusCode && response.statusCode < 400) {
            return @"NSURLSession request succeeded";
        }
        if (400 <= response.statusCode && response.statusCode < 500) {
            return @"NSURLSession request failed";
        }
    }
    return @"NSURLSession request error";
}

+ (nullable NSDictionary<NSString *, id> *)urlParamsForQueryItems:(nullable NSArray<NSURLQueryItem *> *)queryItems {
    if (!queryItems) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSURLQueryItem *item in queryItems) {
        // - note: If a NSURLQueryItem name-value pair is empty (i.e. the query string starts with '&', ends
        // with '&', or has "&&" within it), you get a NSURLQueryItem with a zero-length name and a nil value.
        // If a NSURLQueryItem name-value pair has nothing before the equals sign, you get a zero-length name.
        // If a NSURLQueryItem name-value pair has nothing after the equals sign, you get a zero-length value.
        // If a NSURLQueryItem name-value pair has no equals sign, the NSURLQueryItem name-value pair string
        // is the name and you get a nil value.
        id value = item.value ? item.value : [NSNull null];
        
        if ([result[item.name] isKindOfClass:[NSMutableArray class]]) {
            [result[item.name] addObject:value];
        } else if (result[item.name]) {
            result[item.name] = [NSMutableArray arrayWithObjects:result[item.name], value, nil];
        } else {
            result[item.name] = value;
        }
    }
    return result;
}

+ (nonnull NSString *)URLStringWithoutQueryForComponents:(nonnull NSURLComponents *)URLComponents {
    if (URLComponents.rangeOfQuery.location == NSNotFound) {
        return URLComponents.string;
    }
    NSRange rangeOfQuery = URLComponents.rangeOfQuery;
    NSString *string = [URLComponents.string stringByReplacingCharactersInRange:rangeOfQuery withString:@""];
    // rangeOfQuery does not include the '?' character, so that must be removed separately
    if ([string characterAtIndex:rangeOfQuery.location - 1] == '?') {
        string = [string stringByReplacingCharactersInRange:NSMakeRange(rangeOfQuery.location - 1, 1) withString:@""];
    }
    return string;
}

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    if (g_sink != nil) {
        NSURLRequest *req = task.originalRequest ? task.originalRequest : task.currentRequest;
        if (req == nil) {
            return;
        }

        NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
        metadata[@"duration"] = @((unsigned)(metrics.taskInterval.duration * 1000));
        metadata[@"method"] = req.HTTPMethod;
        if (req.URL) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:req.URL resolvingAgainstBaseURL:YES];
            metadata[@"url"] = [BSGURLSessionTracingDelegate URLStringWithoutQueryForComponents:urlComponents];
            metadata[@"urlParams"] = [BSGURLSessionTracingDelegate urlParamsForQueryItems:urlComponents.queryItems];
        }

        if (task.countOfBytesSent) {
            metadata[@"requestContentLength"] = @(task.countOfBytesSent);
        } else if (req.HTTPBody) {
            // Fall back because task.countOfBytesSent is 0 when a custom NSURLProtocol is used
            metadata[@"requestContentLength"] = @(req.HTTPBody.length);
        }

        // Note: Cannot use metrics transaction response because it will be nil if a custom NSURLProtocol is present.
        // Note: If there was an error, task.response will be nil, and the following values will be set accordingly.
        NSHTTPURLResponse *httpResp = [task.response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)task.response : nil;
        if (httpResp) {
            metadata[@"responseContentLength"] = @(task.countOfBytesReceived);
            metadata[@"status"] = @(httpResp.statusCode);
        }

        NSString *message = [BSGURLSessionTracingDelegate messageForResponse:httpResp];
        [g_sink leaveBreadcrumbWithMessage:message metadata:metadata andType:BSGBreadcrumbTypeRequest];
    }
}

@end
