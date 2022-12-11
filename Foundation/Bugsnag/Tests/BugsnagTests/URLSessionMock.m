//
//  URLSessionMock.m
//  Bugsnag
//
//  Created by Nick Dowell on 19/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "URLSessionMock.h"

@interface URLSessionUploadTaskMock : NSURLSessionUploadTask

@property dispatch_block_t mock;

@end

#pragma mark -

@implementation URLSessionMock {
    NSData *_data;
    NSURLResponse *_response;
    NSError *_error;
}

- (void)mockData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    _data = data;
    _response = response;
    _error = error;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData
                                completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    URLSessionUploadTaskMock *task = [[URLSessionUploadTaskMock alloc] init];
    task.mock = ^{ completionHandler(self->_data, self->_response, self->_error); };
    return task;
}

@end

#pragma mark -

@implementation URLSessionUploadTaskMock

- (void)resume {
    self.mock();
}

@end
