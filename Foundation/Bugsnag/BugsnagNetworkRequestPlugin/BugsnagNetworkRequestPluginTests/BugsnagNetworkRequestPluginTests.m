//
//  BugsnagNetworkRequestPluginTests.m
//  BugsnagNetworkRequestPluginTests
//
//  Created by Karl Stenerud on 26.08.21.
//

#import "BSGURLSessionTracingDelegate.h"

#import <XCTest/XCTest.h>

// Cannot #import "BSGNetworkBreadcrumb.h" from this target
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0))
BugsnagBreadcrumb * _Nullable BSGNetworkBreadcrumbWithTaskMetrics(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics);

#define ONE_SECOND_IN_NS 1000000000ULL

#pragma mark MockURLProtocol

@interface MockURLProtocol: NSURLProtocol
@end

@implementation MockURLProtocol

static NSInteger mock_nextStatusCode;
static NSData *mock_nextData;

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)stopLoading {
}

- (void)startLoading {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:mock_nextStatusCode HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)mock_nextData.length]}];

    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    if (mock_nextData) {
        [self.client URLProtocol:self didLoadData:mock_nextData];
    }
    [self.client URLProtocolDidFinishLoading:self];
}

+ (void)setNextStatusCode:(NSInteger)statusCode data:(NSData *)data {
    mock_nextStatusCode = statusCode;
    mock_nextData = data;
}

@end

#pragma mark BugsnagNetworkRequestPluginTests

@interface BugsnagNetworkRequestPluginTests : XCTestCase

@property(nonatomic, strong) NSMutableArray<BugsnagBreadcrumb *> *breadcrumbs;

@end

@interface BugsnagBreadcrumb ()
+ (nullable instancetype)breadcrumbWithBlock:(void (^)(BugsnagBreadcrumb *))block;
@end

@implementation BugsnagNetworkRequestPluginTests

- (void)leaveNetworkRequestBreadcrumbForTask:(NSURLSessionTask *)task
                                     metrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    BugsnagBreadcrumb *breadcrumb = BSGNetworkBreadcrumbWithTaskMetrics(task, metrics);
    if (breadcrumb) {
        [self.breadcrumbs addObject:breadcrumb];
    }
}

- (NSURLSessionConfiguration *)newMockSessionConfiguraion {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.protocolClasses = @[MockURLProtocol.class];
    return config;
}

- (void)resetBreadcrumbs {
    self.breadcrumbs = [NSMutableArray new];
}

- (void)setUp {
    [BSGURLSessionTracingDelegate setClient:(id)self];
    [self resetBreadcrumbs];
}

- (NSURLSessionConfiguration *)defaultConfig {
    return [NSURLSessionConfiguration defaultSessionConfiguration];
}

- (NSURLSessionConfiguration *)mockConfig {
    return [self newMockSessionConfiguraion];
}

- (NSData *)dataOfLength:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    for (NSUInteger i = 0; i < data.length; i++) {
        ((char*)data.mutableBytes)[i] = 'a';
    }
    return data;
}

- (void)expectMessage:(NSString *)message
               method:(NSString *)method
            reqLength:(NSNumber *)reqLength
           respLength:(NSNumber *)respLength
               status:(NSNumber *)statusCode
                  url:(NSString *)urlString
               params:(NSDictionary *)params {
    XCTAssertEqual(self.breadcrumbs.count, 1);
    BugsnagBreadcrumb *crumb = self.breadcrumbs.lastObject;
    XCTAssertEqual(crumb.type, BSGBreadcrumbTypeRequest);
    XCTAssertEqualObjects(crumb.message, message);
    NSDictionary *metadata = crumb.metadata;
    // duration will be tested in e2e tests
    XCTAssertEqualObjects(metadata[@"method"], method);
    XCTAssertEqualObjects(metadata[@"requestContentLength"], reqLength);
    XCTAssertEqualObjects(metadata[@"responseContentLength"], respLength);
    XCTAssertEqualObjects(metadata[@"status"], statusCode);
    XCTAssertEqualObjects(metadata[@"url"], urlString);
    XCTAssertEqualObjects(metadata[@"urlParams"], params);
}

- (void)waitForTask:(NSURLSessionTask *)task {
    while (task.state == NSURLSessionTaskStateRunning) {
        [NSThread sleepForTimeInterval:0.01];
    }
}

typedef void (^CompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

#pragma mark Basic Fetch

- (void)fetchAndWaitURL: (NSString *) urlString usingConfig:(NSURLSessionConfiguration *)config {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask * task = [session dataTaskWithURL:url completionHandler:^(__unused NSData * _Nullable data, __unused NSURLResponse * _Nullable response, __unused NSError * _Nullable error) {
        dispatch_semaphore_signal(semaphore);
        [session finishTasksAndInvalidate];
    }];
    
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

#pragma mark DataTask

- (void)runDataTaskWithSession:(NSURLSession *)session
                     urlString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask * task = [session dataTaskWithURL:url];
    [task resume];
    [self waitForTask:task];
}

- (void)runDataTaskWithSession:(NSURLSession *)session
                     urlString:(NSString *)urlString
             completionHandler:(CompletionHandler)completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask * task = [session dataTaskWithURL:url completionHandler:^(__unused NSData * _Nullable data, __unused NSURLResponse * _Nullable response, __unused NSError * _Nullable error) {
        completionHandler(data, response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

- (void)runDataTaskWithSession:(NSURLSession *)session
                       request:(NSURLRequest *)request {
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request];
    [task resume];
    [self waitForTask:task];
}

- (void)runDataTaskWithSession:(NSURLSession *)session
                       request:(NSURLRequest *)request
             completionHandler:(CompletionHandler)completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(__unused NSData * _Nullable data, __unused NSURLResponse * _Nullable response, __unused NSError * _Nullable error) {
        completionHandler(data, response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

- (void)runDataTasksWithURL:(NSString *)urlString
                     method:(NSString *)httpMethod
                 statusCode:(NSInteger)statusCode
                       data:(NSData *)data
                  validator:(void(^)(void))validator {

    [MockURLProtocol setNextStatusCode:statusCode data:data];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.mockConfig];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = httpMethod;

    if ([httpMethod isEqual:@"GET"]) {
        [self runDataTaskWithSession:session urlString:urlString];
        validator();

        [self resetBreadcrumbs];
        [self runDataTaskWithSession:session urlString:urlString completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        }];
        validator();
    }

    [self resetBreadcrumbs];
    [self runDataTaskWithSession:session request:request];
    validator();

    [self resetBreadcrumbs];
    [self runDataTaskWithSession:session request:request completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
    }];
    validator();
}

#pragma mark Multipart Task

// Note: The length of this multipart content is 100347 bytes
- (void)runMultipartTasksWithURL:(NSString *)urlString
                          method:(NSString *)httpMethod
                      statusCode:(NSInteger)statusCode
                            data:(NSData *)data
                       validator:(void(^)(void))validator {
    [MockURLProtocol setNextStatusCode:statusCode data:data];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.mockConfig];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = httpMethod;

    NSString *boundary = @"srngsoe5thw4oi5gnsroi5hw48phaeo8rghazs84lhwsiegnsle5hiw4o5";
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", @"my_caption"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", @"My Caption"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=blah.jpg\r\n", @"my_image"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self dataOfLength:100000]];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];

    [self resetBreadcrumbs];
    [self runDataTaskWithSession:session request:request];
    validator();

    [self resetBreadcrumbs];
    [self runDataTaskWithSession:session request:request completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
    }];
    validator();
}

#pragma mark DownloadTask

- (void)runDownloadTaskWithSession:(NSURLSession *)session
                         urlString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
    [task resume];
    [self waitForTask:task];
}

- (void)runDownloadTaskWithSession:(NSURLSession *)session
                         urlString:(NSString *)urlString
                 completionHandler:(CompletionHandler)completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completionHandler([NSData data], response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

- (void)runDownloadTaskWithSession:(NSURLSession *)session
                           request:(NSURLRequest *)request {
    NSURLSessionDownloadTask * task = [session downloadTaskWithRequest:request];
    [task resume];
    [self waitForTask:task];
}

- (void)runDownloadTaskWithSession:(NSURLSession *)session
                           request:(NSURLRequest *)request
                 completionHandler:(CompletionHandler)completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completionHandler([NSData data], response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

- (void)runDownloadTasksWithURL:(NSString *)urlString
                         method:(NSString *)httpMethod
                     statusCode:(NSInteger)statusCode
                           data:(NSData *)data
                      validator:(void(^)(void))validator {

    [MockURLProtocol setNextStatusCode:statusCode data:data];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.mockConfig];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = httpMethod;

    if ([httpMethod isEqual:@"GET"]) {
        [self runDownloadTaskWithSession:session urlString:urlString];
        validator();

        [self resetBreadcrumbs];
        [self runDownloadTaskWithSession:session urlString:urlString completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        }];
        validator();
    }

    [self resetBreadcrumbs];
    [self runDownloadTaskWithSession:session request:request];
    validator();

    [self resetBreadcrumbs];
    [self runDownloadTaskWithSession:session request:request completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
    }];
    validator();
}

#pragma mark UploadTask

- (void)runUploadTaskWithSession:(NSURLSession *)session
                         request:(NSURLRequest *)request
                        fromData:(NSData *)fromData {
    NSURLSessionUploadTask * task = [session uploadTaskWithRequest:request fromData:fromData];
    [task resume];
    [self waitForTask:task];
}

- (void)runUploadTaskWithSession:(NSURLSession *)session
                         request:(NSURLRequest *)request
                        fromData:(NSData *)fromData
               completionHandler:(CompletionHandler)completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:fromData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completionHandler(data, response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, ONE_SECOND_IN_NS));
}

- (void)runUploadTasksWithURL:(NSString *)urlString
                     statusCode:(NSInteger)statusCode
                           data:(NSData *)data
                      validator:(void(^)(void))validator {

    [MockURLProtocol setNextStatusCode:statusCode data:data];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.mockConfig];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];

    [self resetBreadcrumbs];
    [self runUploadTaskWithSession:session request:request fromData:data];
    validator();

    [self resetBreadcrumbs];
    [self runUploadTaskWithSession:session request:request fromData:data completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
    }];
    validator();
}

#pragma mark Unit Tests

- (void)testBadURL {
    [self resetBreadcrumbs];
    [self fetchAndWaitURL:@"xxxxxxx" usingConfig:self.defaultConfig];
    [self expectMessage:@"NSURLSession request error"
                 method:@"GET"
              reqLength:nil
             respLength:nil
                 status:nil
                    url:@"xxxxxxx"
                 params:nil];
}

- (void)testDataTaskEmpty {
    [self resetBreadcrumbs];
    NSString *urlString = @"https://bugsnag.com";
    [self runDataTasksWithURL:urlString
                       method:@"GET"
                   statusCode:200
                         data:[self dataOfLength:0]
                    validator:^{
        [self expectMessage:@"NSURLSession request succeeded"
                     method:@"GET"
                  reqLength:nil
                 respLength:@0
                     status:@200
                        url:urlString
                     params:nil];
    }];
}

- (void)testDataTaskNonEmpty {
    [self resetBreadcrumbs];
    NSString *urlString = @"https://bugsnag.com";
    [self runDataTasksWithURL:urlString
                       method:@"GET"
                   statusCode:200
                         data:[self dataOfLength:10]
                    validator:^{
        [self expectMessage:@"NSURLSession request succeeded"
                     method:@"GET"
                  reqLength:nil
                 respLength:@10
                     status:@200
                        url:urlString
                     params:nil];
    }];
}

- (void)testTaskStatusCodes {
    NSArray *expectedMessages = @[
        @"",
        @"NSURLSession request succeeded",
        @"NSURLSession request succeeded",
        @"NSURLSession request succeeded",
        @"NSURLSession request failed",
        @"NSURLSession request error",
    ];
    NSString *urlString = @"https://bugsnag.com";

    for (NSInteger i = 100; i <= 500; i+= 100) {
        NSInteger statusCode = i + 5;
        NSString *expectedMessage = expectedMessages[(NSUInteger)statusCode/100];

        [self resetBreadcrumbs];
        [self runDataTasksWithURL:urlString
                           method:@"GET"
                       statusCode:statusCode
                             data:[self dataOfLength:0]
                        validator:^{
            [self expectMessage:expectedMessage
                         method:@"GET"
                      reqLength:nil
                     respLength:@0
                         status:@(statusCode)
                            url:urlString
                         params:nil];
        }];

#if !TARGET_OS_WATCH
        // TODO: Rewrite these to support the much more strict HTTP library in watchOS and later iOS
        [self resetBreadcrumbs];
        [self runMultipartTasksWithURL:urlString
                           method:@"GET"
                       statusCode:statusCode
                             data:[self dataOfLength:10]
                        validator:^{
            [self expectMessage:expectedMessage
                         method:@"GET"
                      reqLength:@100347 // Length of multipart content
                     respLength:@10
                         status:@(statusCode)
                            url:urlString
                         params:nil];
        }];
#endif

        [self resetBreadcrumbs];
        [self runDownloadTasksWithURL:urlString
                           method:@"GET"
                       statusCode:statusCode
                             data:[self dataOfLength:100]
                        validator:^{
            [self expectMessage:expectedMessage
                         method:@"GET"
                      reqLength:nil
                     respLength:@100
                         status:@(statusCode)
                            url:urlString
                         params:nil];
        }];

#if !TARGET_OS_WATCH
        // TODO: Rewrite these to support the much more strict HTTP library in watchOS and later iOS
        [self resetBreadcrumbs];
        [self runUploadTasksWithURL:urlString
                       statusCode:statusCode
                             data:[self dataOfLength:5109]
                        validator:^{
            [self expectMessage:expectedMessage
                         method:@"GET"
                      reqLength:nil
                     respLength:@5109
                         status:@(statusCode)
                            url:urlString
                         params:nil];
        }];
#endif
    }
}

- (void)testTaskMethods {
#if TARGET_OS_WATCH
    // TODO: Rewrite these to support the much more strict HTTP library in watchOS and later iOS
    for (NSString *method in @[@"GET", @"HEAD"]) {
#else
    for (NSString *method in @[@"GET", @"HEAD", @"POST", @"PUT", @"DELETE", @"CONNECT", @"OPTIONS", @"TRACE", @"PATCH"]) {
#endif
        [self resetBreadcrumbs];
        [self runDataTasksWithURL:@"https://bugsnag.com/?a=b&c=d"
                           method:method
                       statusCode:200
                             data:[self dataOfLength:0]
                        validator:^{
            [self expectMessage:@"NSURLSession request succeeded"
                         method:method
                      reqLength:nil
                     respLength:@0
                         status:@200
                            url:@"https://bugsnag.com/"
                         params:@{@"a": @"b", @"c": @"d"}];
        }];
        
        [self resetBreadcrumbs];
        [self runDownloadTasksWithURL:@"https://bugsnag.com?a=b&c=d"
                               method:method
                           statusCode:200
                                 data:[self dataOfLength:0]
                            validator:^{
            [self expectMessage:@"NSURLSession request succeeded"
                         method:method
                      reqLength:nil
                     respLength:@0
                         status:@200
                            url:@"https://bugsnag.com"
                         params:@{@"a": @"b", @"c": @"d"}];
        }];
    }
}

@end


