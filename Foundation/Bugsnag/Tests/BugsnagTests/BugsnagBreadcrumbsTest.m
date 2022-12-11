//
//  BugsnagBreadcrumbsTest.m
//  Bugsnag
//
//  Created by Delisa Mason on 9/16/15.
//
//

#import "BSGUtils.h"
#import "BSG_KSJSONCodec.h"
#import "Bugsnag.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagBreadcrumbs.h"
#import "BugsnagClient+Private.h"
#import "BugsnagTestConstants.h"
#import "BSGDefines.h"

#import <XCTest/XCTest.h>
#import <mach/mach_init.h>
#import <mach/thread_act.h>
#import <pthread.h>

// Defined in BSG_KSCrashReport.c
void bsg_kscrw_i_prepareReportWriter(BSG_KSCrashReportWriter *const writer, BSG_KSJSONEncodeContext *const context);

struct json_buffer {
    size_t length;
    char *buffer;
};

static int json_buffer_append(const char *data, size_t length, struct json_buffer *buffer) {
    memcpy(buffer->buffer + buffer->length, data, length);
    buffer->length += length;
    return BSG_KSJSON_OK;
}

static int addJSONData(const char *data, size_t length, NSMutableData *userData) {
    [userData appendBytes:data length:length];
    return BSG_KSJSON_OK;
}

static id JSONObject(void (^ block)(BSG_KSCrashReportWriter *writer)) {
    NSMutableData *data = [NSMutableData data];
    BSG_KSJSONEncodeContext encodeContext;
    BSG_KSCrashReportWriter reportWriter;
    bsg_kscrw_i_prepareReportWriter(&reportWriter, &encodeContext);
    bsg_ksjsonbeginEncode(&encodeContext, false, (BSG_KSJSONAddDataFunc)addJSONData, (__bridge void *)data);
    block(&reportWriter);
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
}

static BugsnagBreadcrumb * WithBlock(void (^ block)(BugsnagBreadcrumb *breadcrumb)) {
    BugsnagBreadcrumb *breadcrumb = [BugsnagBreadcrumb new];
    block(breadcrumb);
    return breadcrumb;
}

static BugsnagBreadcrumb * WithMessage(NSString *message) {
    return WithBlock(^(BugsnagBreadcrumb *breadcrumb) {
        breadcrumb.message = message;
    });
}

@interface BugsnagBreadcrumbsTest : XCTestCase
@property(nonatomic, strong) BugsnagBreadcrumbs *crumbs;
@end

@interface BugsnagBreadcrumbs (Testing)
- (NSArray<NSDictionary *> *)arrayValue;
@end

void awaitBreadcrumbSync(BugsnagBreadcrumbs *crumbs) {
    dispatch_sync(BSGGetFileSystemQueue(), ^{});
}

BSGBreadcrumbType BSGBreadcrumbTypeFromString(NSString *value);

@implementation BugsnagBreadcrumbsTest

- (void)setUp {
    [super setUp];
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagBreadcrumbs *crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [crumbs removeAllBreadcrumbs];
    [crumbs addBreadcrumb:WithMessage(@"Launch app")];
    [crumbs addBreadcrumb:WithMessage(@"Tap button")];
    [crumbs addBreadcrumb:WithMessage(@"Close tutorial")];
    self.crumbs = crumbs;
}

- (void)tearDown {
    awaitBreadcrumbSync(self.crumbs);
}

- (void)testDefaultCount {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagBreadcrumbs *crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [crumbs removeAllBreadcrumbs];
    XCTAssertTrue(crumbs.breadcrumbs.count == 0);
}

- (void)testMaxBreadcrumbs {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.maxBreadcrumbs = 3;
    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs removeAllBreadcrumbs];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 1")];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 2")];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 3")];
    [self.crumbs addBreadcrumb:WithMessage(@"Clear notifications")];
    awaitBreadcrumbSync(self.crumbs);
    NSArray<BugsnagBreadcrumb *> *breadcrumbs = self.crumbs.breadcrumbs;
    XCTAssertEqual(breadcrumbs.count, 3);
    XCTAssertEqualObjects(breadcrumbs[0].message, @"Crumb 2");
    XCTAssertEqualObjects(breadcrumbs[1].message, @"Crumb 3");
    XCTAssertEqualObjects(breadcrumbs[2].message, @"Clear notifications");
}

- (void)testBreadcrumbsInvalidKey {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagOnBreadcrumbBlock crumbBlock = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        return YES;
    };
    [config addOnBreadcrumbBlock:crumbBlock];

    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeState;
        crumb.message = @"message";
        crumb.metadata = @{@123 : @"would raise exception"};
    })];
    awaitBreadcrumbSync(self.crumbs);
}

- (void)testEmptyCapacity {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.maxBreadcrumbs = 0;
    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs removeAllBreadcrumbs];
    [self.crumbs addBreadcrumb:WithMessage(@"Clear notifications")];
    XCTAssertEqual(self.crumbs.breadcrumbs.count, 0);
}

- (void)testArrayValue {
    awaitBreadcrumbSync(self.crumbs);
    NSArray *value = [self.crumbs arrayValue];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.count == 3);
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSX5";
    for (int i = 0; i < value.count; i++) {
        NSDictionary *item = value[i];
        XCTAssertTrue([item isKindOfClass:[NSDictionary class]]);
        XCTAssertEqualObjects(item[@"type"], @"manual");
        XCTAssertTrue([[formatter dateFromString:item[@"timestamp"]]
                       isKindOfClass:[NSDate class]]);
    }
    XCTAssertEqualObjects(value[0][@"name"], @"Launch app");
    XCTAssertEqualObjects(value[1][@"name"], @"Tap button");
    XCTAssertEqualObjects(value[2][@"name"], @"Close tutorial");
}

- (void)testStateType {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagBreadcrumbs *crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [crumbs removeAllBreadcrumbs];
    [crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeState;
        crumb.message = @"Rotated Menu";
        crumb.metadata = @{@"direction" : @"right"};
    })];
    awaitBreadcrumbSync(self.crumbs);
    NSArray *value = [crumbs arrayValue];
    XCTAssertEqualObjects(value[0][@"metaData"][@"direction"], @"right");
    XCTAssertEqualObjects(value[0][@"name"], @"Rotated Menu");
    XCTAssertEqualObjects(value[0][@"type"], @"state");
}

- (void)testPersistentCrumbManual {
    awaitBreadcrumbSync(self.crumbs);
    NSArray<BugsnagBreadcrumb *> *breadcrumbs = [self.crumbs cachedBreadcrumbs];
    XCTAssertEqual(breadcrumbs.count, 3);
    XCTAssertEqual(breadcrumbs[0].type, BSGBreadcrumbTypeManual);
    XCTAssertEqualObjects(breadcrumbs[0].message, @"Launch app");
    XCTAssertNotNil(breadcrumbs[0].timestamp);
    XCTAssertEqual(breadcrumbs[1].type, BSGBreadcrumbTypeManual);
    XCTAssertEqualObjects(breadcrumbs[1].message, @"Tap button");
    XCTAssertNotNil(breadcrumbs[1].timestamp);
    XCTAssertEqual(breadcrumbs[2].type, BSGBreadcrumbTypeManual);
    XCTAssertEqualObjects(breadcrumbs[2].message, @"Close tutorial");
    XCTAssertNotNil(breadcrumbs[2].timestamp);
}

- (void)testPersistentCrumbCustom {
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *crumb) {
        crumb.message = @"Initiate sequence";
        crumb.metadata = @{ @"captain": @"Bob"};
        crumb.type = BSGBreadcrumbTypeState;
    })];
    awaitBreadcrumbSync(self.crumbs);
    NSArray<BugsnagBreadcrumb *> *breadcrumbs = [self.crumbs cachedBreadcrumbs];
    XCTAssertEqual(breadcrumbs.count, 4);
    XCTAssertEqual(breadcrumbs[3].type, BSGBreadcrumbTypeState);
    XCTAssertEqualObjects(breadcrumbs[3].message, @"Initiate sequence");
    XCTAssertEqualObjects(breadcrumbs[3].metadata[@"captain"], @"Bob");
    XCTAssertNotNil(breadcrumbs[3].timestamp);
}

- (void)testDefaultDiscardByType {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs removeAllBreadcrumbs];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeState;
        crumb.message = @"state";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeUser;
        crumb.message = @"user";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeLog;
        crumb.message = @"log";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeError;
        crumb.message = @"error";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeProcess;
        crumb.message = @"process";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeRequest;
        crumb.message = @"request";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeNavigation;
        crumb.message = @"navigation";
    })];
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.message = @"manual";
    })];
    awaitBreadcrumbSync(self.crumbs);
    NSArray *value = [self.crumbs arrayValue];
    XCTAssertEqual(8, value.count);
    XCTAssertEqualObjects(value[0][@"type"], @"state");
    XCTAssertEqualObjects(value[1][@"type"], @"user");
    XCTAssertEqualObjects(value[2][@"type"], @"log");
    XCTAssertEqualObjects(value[3][@"type"], @"error");
    XCTAssertEqualObjects(value[4][@"type"], @"process");
    XCTAssertEqualObjects(value[5][@"type"], @"request");
    XCTAssertEqualObjects(value[6][@"type"], @"navigation");
    XCTAssertEqualObjects(value[7][@"type"], @"manual");
}

- (void)testAlwaysAllowManual {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs removeAllBreadcrumbs];
    [self.crumbs addBreadcrumb:WithMessage(@"this is a test")];
    awaitBreadcrumbSync(self.crumbs);
    NSArray *value = [self.crumbs arrayValue];
    XCTAssertEqual(1, value.count);
    XCTAssertEqualObjects(value[0][@"type"], @"manual");
    XCTAssertEqualObjects(value[0][@"name"], @"this is a test");
}

/**
 * enabledBreadcrumbTypes filtering only happens on the client.  The BugsnagBreadcrumbs container is
 * private and assumes filtering is already configured.
 */
- (void)testDiscardByTypeDoesNotApply {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    self.crumbs = [[BugsnagBreadcrumbs alloc] initWithConfiguration:config];
    [self.crumbs removeAllBreadcrumbs];
    // Don't discard this
    [self.crumbs addBreadcrumb:WithBlock(^(BugsnagBreadcrumb *_Nonnull crumb) {
        crumb.type = BSGBreadcrumbTypeState;
        crumb.message = @"state";
    })];
    awaitBreadcrumbSync(self.crumbs);
    NSArray *value = [self.crumbs arrayValue];
    XCTAssertEqual(1, value.count);
}

- (void)testConvertBreadcrumbTypeFromString {
    XCTAssertEqual(BSGBreadcrumbTypeState, BSGBreadcrumbTypeFromString(@"state"));
    XCTAssertEqual(BSGBreadcrumbTypeUser, BSGBreadcrumbTypeFromString(@"user"));
    XCTAssertEqual(BSGBreadcrumbTypeManual, BSGBreadcrumbTypeFromString(@"manual"));
    XCTAssertEqual(BSGBreadcrumbTypeNavigation, BSGBreadcrumbTypeFromString(@"navigation"));
    XCTAssertEqual(BSGBreadcrumbTypeProcess, BSGBreadcrumbTypeFromString(@"process"));
    XCTAssertEqual(BSGBreadcrumbTypeLog, BSGBreadcrumbTypeFromString(@"log"));
    XCTAssertEqual(BSGBreadcrumbTypeRequest, BSGBreadcrumbTypeFromString(@"request"));
    XCTAssertEqual(BSGBreadcrumbTypeError, BSGBreadcrumbTypeFromString(@"error"));

    XCTAssertEqual(BSGBreadcrumbTypeManual, BSGBreadcrumbTypeFromString(@"random"));
    XCTAssertEqual(BSGBreadcrumbTypeManual, BSGBreadcrumbTypeFromString(@"4"));
}

- (void)testBreadcrumbsBeforeDate {
    [self.crumbs removeAllBreadcrumbs];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 1")];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 2")];
    [self.crumbs addBreadcrumb:WithMessage(@"Crumb 3")];
    XCTAssertEqual([self.crumbs breadcrumbsBeforeDate:[NSDate date]].count, 3);
    XCTAssertEqual([self.crumbs breadcrumbsBeforeDate:[NSDate distantPast]].count, 0);
}

- (void)testBreadcrumbFromDict {
    XCTAssertNil([BugsnagBreadcrumb breadcrumbFromDict:@{}]);
    XCTAssertNil([BugsnagBreadcrumb breadcrumbFromDict:@{@"metadata": @{}}]);
    XCTAssertNil([BugsnagBreadcrumb breadcrumbFromDict:@{@"timestamp": @""}]);
    BugsnagBreadcrumb *crumb = [BugsnagBreadcrumb breadcrumbFromDict:@{
        @"timestamp": @"0",
        @"metaData": @{},
        @"message":@"cache break",
        @"type":@"process"}];
    XCTAssertNil(crumb);

    crumb = [BugsnagBreadcrumb breadcrumbFromDict:@{
        @"timestamp": @"2020-02-14T16:12:22+001",
        @"metaData": @{},
        @"message":@"",
        @"type":@"process"}];
    XCTAssertNil(crumb);

    crumb = [BugsnagBreadcrumb breadcrumbFromDict:@{
        @"timestamp": @"2020-02-14T16:12:23+001",
        @"metaData": @{},
        @"message":@"cache break",
        @"type":@"process"}];
    XCTAssertNotNil(crumb);
    XCTAssertEqualObjects(@{}, crumb.metadata);
    XCTAssertEqualObjects(@"cache break", crumb.message);
    XCTAssertEqual(BSGBreadcrumbTypeProcess, crumb.type);

    crumb = [BugsnagBreadcrumb breadcrumbFromDict:@{
        @"timestamp": @"2020-02-14T16:14:23+001",
        @"metaData": @{@"foo": @"bar"},
        @"message":@"cache break",
        @"type":@"log"}];
    XCTAssertNotNil(crumb);
    XCTAssertEqualObjects(@"cache break", crumb.message);
    XCTAssertEqualObjects(@{@"foo": @"bar"}, crumb.metadata);
    XCTAssertEqual(BSGBreadcrumbTypeLog, crumb.type);
}

/**
 * Test that breadcrumb operations with no callback block work as expected.  1 of 2
 */
- (void)testCallbackFreeConstructors2 {
    // Prevent sending events
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    NSDictionary *md1 = @{ @"x" : @"y"};
    NSDictionary *md2 = @{ @"a" : @"b",
                           @"c" : @42};

    [client leaveBreadcrumbWithMessage:@"manual message" metadata:md1 andType:BSGBreadcrumbTypeManual];
    [client leaveBreadcrumbWithMessage:@"log message" metadata:md2 andType:BSGBreadcrumbTypeLog];
    [client leaveBreadcrumbWithMessage:@"navigation message" metadata:md1 andType:BSGBreadcrumbTypeNavigation];
    [client leaveBreadcrumbWithMessage:@"process message" metadata:md2 andType:BSGBreadcrumbTypeProcess];
    [client leaveBreadcrumbWithMessage:@"request message" metadata:md1 andType:BSGBreadcrumbTypeRequest];
    [client leaveBreadcrumbWithMessage:@"state message" metadata:md2 andType:BSGBreadcrumbTypeState];
    [client leaveBreadcrumbWithMessage:@"user message" metadata:md1 andType:BSGBreadcrumbTypeUser];

    NSDictionary *bc0 = [client.breadcrumbs[0] objectValue];
    NSDictionary *bc1 = [client.breadcrumbs[1] objectValue];
    NSDictionary *bc2 = [client.breadcrumbs[2] objectValue];
    NSDictionary *bc3 = [client.breadcrumbs[3] objectValue];
    NSDictionary *bc4 = [client.breadcrumbs[4] objectValue];
    NSDictionary *bc5 = [client.breadcrumbs[5] objectValue];
    NSDictionary *bc6 = [client.breadcrumbs[6] objectValue];
    NSDictionary *bc7 = [client.breadcrumbs[7] objectValue];

    XCTAssertEqual(client.breadcrumbs.count, 8);

    XCTAssertEqualObjects(bc0[@"type"], @"state");
    XCTAssertEqualObjects(bc0[@"name"], @"Bugsnag loaded");
    XCTAssertEqual([bc0[@"metaData"] count], 0);

    XCTAssertEqual([bc1[@"metaData"] count], 1);
    XCTAssertEqual([bc3[@"metaData"] count], 1);
    XCTAssertEqual([bc5[@"metaData"] count], 1);
    XCTAssertEqual([bc7[@"metaData"] count], 1);

    XCTAssertEqual([bc2[@"metaData"] count], 2);
    XCTAssertEqual([bc4[@"metaData"] count], 2);
    XCTAssertEqual([bc6[@"metaData"] count], 2);
    
    XCTAssertEqualObjects(bc1[@"name"], @"manual message");
    XCTAssertEqualObjects(bc1[@"type"], @"manual");

    XCTAssertEqualObjects(bc2[@"name"], @"log message");
    XCTAssertEqualObjects(bc2[@"type"], @"log");

    XCTAssertEqualObjects(bc3[@"name"], @"navigation message");
    XCTAssertEqualObjects(bc3[@"type"], @"navigation");

    XCTAssertEqualObjects(bc4[@"name"], @"process message");
    XCTAssertEqualObjects(bc4[@"type"], @"process");

    XCTAssertEqualObjects(bc5[@"name"], @"request message");
    XCTAssertEqualObjects(bc5[@"type"], @"request");

    XCTAssertEqualObjects(bc6[@"name"], @"state message");
    XCTAssertEqualObjects(bc6[@"type"], @"state");

    XCTAssertEqualObjects(bc7[@"name"], @"user message");
    XCTAssertEqualObjects(bc7[@"type"], @"user");

    [client leaveBreadcrumbWithMessage:@"Invalid metadata" metadata:@{@"date": [NSDate distantFuture]} andType:BSGBreadcrumbTypeUser];
    XCTAssertEqual(client.breadcrumbs.count, 9, @"Invalid metadata should not prevent a breadcrumb being left");
    XCTAssertEqualObjects(client.breadcrumbs[8].message, @"Invalid metadata");
    XCTAssertEqualObjects(client.breadcrumbs[8].metadata.allKeys, @[@"date"]);
}

/**
 * Test that breadcrumb operations with no callback block work as expected.  2 of 2
 */
- (void)testCallbackFreeConstructors3 {
    // Prevent sending events
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];
    
    [client leaveBreadcrumbWithMessage:@"message1"];
    [client leaveBreadcrumbWithMessage:@"message2" metadata:nil andType:BSGBreadcrumbTypeUser];
    
    NSDictionary *bc1 = [client.breadcrumbs[1] objectValue];
    NSDictionary *bc2 = [client.breadcrumbs[2] objectValue];

    XCTAssertEqualObjects(bc1[@"name"], @"message1");
    XCTAssertEqualObjects(bc2[@"name"], @"message2");
    
    XCTAssertEqual([bc1[@"metaData"] count], 0);
    XCTAssertEqual([bc2[@"metaData"] count], 0);
}

- (void)testCrashReportWriter {
    NSDictionary<NSString *, id> *object = JSONObject(^(BSG_KSCrashReportWriter *writer) {
        writer->beginObject(writer, "");
        BugsnagBreadcrumbsWriteCrashReport(writer);
        writer->endContainer(writer);
    });
    
    XCTAssertEqualObjects(object.allKeys, @[@"breadcrumbs"]);
    NSArray<NSDictionary *> *breadcrumbs = object[@"breadcrumbs"];
    XCTAssertEqual(breadcrumbs.count, 3);
    
    XCTAssertEqualObjects(breadcrumbs[0][@"type"], @"manual");
    XCTAssertEqualObjects(breadcrumbs[0][@"name"], @"Launch app");
    XCTAssertEqualObjects(breadcrumbs[0][@"metaData"], @{});
    
    XCTAssertEqualObjects(breadcrumbs[1][@"type"], @"manual");
    XCTAssertEqualObjects(breadcrumbs[1][@"name"], @"Tap button");
    XCTAssertEqualObjects(breadcrumbs[1][@"metaData"], @{});
    
    XCTAssertEqualObjects(breadcrumbs[2][@"type"], @"manual");
    XCTAssertEqualObjects(breadcrumbs[2][@"name"], @"Close tutorial");
    XCTAssertEqualObjects(breadcrumbs[2][@"metaData"], @{});
}

static void * executeBlock(void *ptr) {
    ((__bridge_transfer dispatch_block_t)ptr)();
    return NULL;
}

- (void)testCrashReportWriterConcurrency {
#if defined(__has_feature) && __has_feature(thread_sanitizer)
    NSLog(@"Skipping test because ThreadSanitizer deadlocks if other threads are suspended");
    return;
#endif
    //
    // The aim of this test is to ensure that BugsnagBreadcrumbsWriteCrashReport will insert only valid JSON
    // into a crash report when other threads are updating the breadcrumbs linked list.
    //
    // So that the test spends less time serialising breadcrumbs and more time updating the linked list, the
    // breadcrumb data is precomputed and not written to disk.
    //
    NSData *breadcrumbData = [NSJSONSerialization dataWithJSONObject:
                              [WithBlock(^(BugsnagBreadcrumb *breadcrumb) {
        breadcrumb.message = @"Lorem ipsum";
    }) objectValue] options:0 error:nil];
    
    __block BOOL isFinished = NO;
    
    const int threadCount = 6;
    pthread_t threads[threadCount] = {0};
    thread_t machThreads[threadCount] = {0};
    for (int i = 0; i < threadCount; i++) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        thread_t *threadPtr = machThreads + i;
        pthread_create(&threads[i], NULL, executeBlock, (__bridge_retained void *)^{
            *threadPtr = mach_thread_self();
            pthread_setname_np("com.bugsnag.testCrashReportWriterConcurrency.writer");
            dispatch_semaphore_signal(semaphore);
            while (!isFinished) {
                [self.crumbs addBreadcrumbWithData:breadcrumbData writeToDisk:NO];
            }
        });
        // Wait for thread to start executing
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    const size_t bufferSize = 1024 * 1024;
    struct json_buffer buffer = {0};
    buffer.buffer = malloc(bufferSize);
    
    for (int i = 0; i < 5000; i++) {
        buffer.length = 0;
        
        BSG_KSJSONEncodeContext context;
        BSG_KSCrashReportWriter writer;
        bsg_kscrw_i_prepareReportWriter(&writer, &context);
        bsg_ksjsonbeginEncode(&context, false, (BSG_KSJSONAddDataFunc)json_buffer_append, &buffer);
        writer.beginObject(&writer, "");
        BugsnagBreadcrumbsWriteCrashReport(&writer);
        writer.endContainer(&writer);
        
        NSError *error = nil;
        NSData *data = [NSData dataWithBytesNoCopy:buffer.buffer length:buffer.length freeWhenDone:NO];
        if (![NSJSONSerialization JSONObjectWithData:data options:0 error:&error]) {
            [self addAttachment:[XCTAttachment attachmentWithUniformTypeIdentifier:@"public.plain-text"
                                                                              name:@"breadcrumbs.json"
                                                                           payload:data
                                                                          userInfo:nil]];
            XCTFail(@"Breadcrumbs JSON could not be parsed: %@", error);
            break;
        }
    }
    
    free(buffer.buffer);
    isFinished = YES;
    for (int i = 0; i < threadCount; i++) {
        pthread_join(threads[i], NULL);
    }
}

- (void)testPerformance {
    NSInteger maxBreadcrumbs = 100;
    
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    configuration.maxBreadcrumbs = maxBreadcrumbs;
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *event) { return NO; }];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];
    
    [self measureBlock:^{
        for (int i=0; i<maxBreadcrumbs; i++) {
            [client leaveBreadcrumbWithMessage:[NSString stringWithFormat:@"%s %@", __PRETTY_FUNCTION__, [NSDate date]]
                                      metadata:[[NSBundle mainBundle] infoDictionary]
                                       andType:BSGBreadcrumbTypeLog];
        }
    }];
}

@end

#pragma mark -

@implementation BugsnagBreadcrumbs (Testing)

- (NSArray<NSDictionary *> *)arrayValue {
    return [self.breadcrumbs valueForKey:@"objectValue"];
}

@end
