//
//  BSGInternalErrorReporter.m
//  Bugsnag
//
//  Created by Nick Dowell on 06/05/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "BSGInternalErrorReporter.h"

#import "BSGKeys.h"
#import "BSG_KSCrashReportFields.h"
#import "BSG_KSSysCtl.h"
#import "BSG_RFC3339DateTool.h"
#import "BugsnagApiClient.h"
#import "BugsnagCollections.h"
#import "BugsnagError+Private.h"
#import "BugsnagEvent+Private.h"
#import "BugsnagHandledState.h"
#import "BugsnagInternals.h"
#import "BugsnagLogger.h"
#import "BugsnagMetadata+Private.h"
#import "BugsnagNotifier.h"
#import "BugsnagStackframe+Private.h"
#import "BugsnagUser+Private.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#import "BSGUIKit.h"
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

#import <CommonCrypto/CommonDigest.h>

static NSString * const EventPayloadVersion = @"4.0";

static NSString * const BugsnagDiagnosticsKey = @"BugsnagDiagnostics";

static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNameInternalError = @"Bugsnag-Internal-Error";


NSString *BSGErrorDescription(NSError *error) {
    return error ? [NSString stringWithFormat:@"%@ %ld: %@", error.domain, (long)error.code,
                    error.userInfo[NSDebugDescriptionErrorKey] ?: error.localizedDescription] : nil;
}

static NSString * DeviceId(void);

static NSString * Sysctl(const char *name);


// MARK: -

BSG_OBJC_DIRECT_MEMBERS
@interface BSGInternalErrorReporter ()

@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSURL *endpoint;
@property (nonatomic) NSURLSession *session;

@end


BSG_OBJC_DIRECT_MEMBERS
@implementation BSGInternalErrorReporter

static BSGInternalErrorReporter *sharedInstance_;
static void (^ startupBlock_)(BSGInternalErrorReporter *);

+ (BSGInternalErrorReporter *)sharedInstance {
    return sharedInstance_;
}

+ (void)setSharedInstance:(BSGInternalErrorReporter *)sharedInstance {
    sharedInstance_ = sharedInstance;
    if (startupBlock_ && sharedInstance_) {
        startupBlock_(sharedInstance_);
        startupBlock_ = nil;
    }
}

+ (void)performBlock:(void (^)(BSGInternalErrorReporter *))block {
    if (sharedInstance_) {
        block(sharedInstance_);
    } else {
        startupBlock_ = [block copy];
    }
}

- (instancetype)initWithApiKey:(NSString *)apiKey endpoint:(NSURL *)endpoint {
    if ((self = [super init])) {
        _apiKey = apiKey;
        _endpoint = endpoint;
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
    }
    return self;
}

// MARK: Public API

- (void)reportErrorWithClass:(NSString *)errorClass
                     context:(nullable NSString *)context
                     message:(nullable NSString *)message
                 diagnostics:(nullable NSDictionary<NSString *, id> *)diagnostics {
    @try {
        BugsnagEvent *event = [self eventWithErrorClass:errorClass context:context message:message diagnostics:diagnostics];
        if (event) {
            [self sendEvent:event];
        }
    } @catch (NSException *exception) {
        bsg_log_err(@"%@", exception);
    }
}

- (void)reportException:(NSException *)exception
            diagnostics:(nullable NSDictionary<NSString *, id> *)diagnostics
           groupingHash:(nullable NSString *)groupingHash {
    @try {
        BugsnagEvent *event = [self eventWithException:exception diagnostics:diagnostics groupingHash:groupingHash];
        if (event) {
            [self sendEvent:event];
        }
    } @catch (NSException *exception) {
        bsg_log_err(@"%@", exception);
    }
}

- (void)reportRecrash:(NSDictionary *)recrashReport {
    @try {
        BugsnagEvent *event = [self eventWithRecrashReport:recrashReport];
        if (event) {
            [self sendEvent:event];
        }
    } @catch (NSException *exception) {
        bsg_log_err(@"%@", exception);
    }
}

// MARK: Private API

- (nullable BugsnagEvent *)eventWithErrorClass:(NSString *)errorClass
                                       context:(nullable NSString *)context
                                       message:(nullable NSString *)message
                                   diagnostics:(nullable NSDictionary<NSString *, id> *)diagnostics {
    
    BugsnagError *error =
    [[BugsnagError alloc] initWithErrorClass:errorClass
                                errorMessage:message
                                   errorType:BSGErrorTypeCocoa
                                  stacktrace:nil];
    
    return [self eventWithError:error context:context diagnostics:diagnostics groupingHash:nil];
}

- (nullable BugsnagEvent *)eventWithException:(NSException *)exception
                                  diagnostics:(nullable NSDictionary<NSString *, id> *)diagnostics
                                 groupingHash:(nullable NSString *)groupingHash {
    
    NSArray<BugsnagStackframe *> *stacktrace = [BugsnagStackframe stackframesWithCallStackReturnAddresses:exception.callStackReturnAddresses];
    
    BugsnagError *error =
    [[BugsnagError alloc] initWithErrorClass:exception.name
                                errorMessage:exception.reason
                                   errorType:BSGErrorTypeCocoa
                                  stacktrace:stacktrace];
    
    return [self eventWithError:error context:nil diagnostics:diagnostics groupingHash:groupingHash];
}

- (nullable BugsnagEvent *)eventWithRecrashReport:(NSDictionary *)recrashReport {
    NSString *reportType = recrashReport[@ BSG_KSCrashField_Report][@ BSG_KSCrashField_Type];
    if (![reportType isEqualToString:@ BSG_KSCrashReportType_Minimal]) {
        return nil;
    }
    
    NSDictionary *crash = recrashReport[@ BSG_KSCrashField_Crash];
    NSDictionary *crashedThread = crash[@ BSG_KSCrashField_CrashedThread];
    
    NSArray *backtrace = crashedThread[@ BSG_KSCrashField_Backtrace][@ BSG_KSCrashField_Contents];
    NSArray *binaryImages = recrashReport[@ BSG_KSCrashField_BinaryImages];
    NSArray<BugsnagStackframe *> *stacktrace = BSGDeserializeArrayOfObjects(backtrace, ^BugsnagStackframe *(NSDictionary *dict) {
        return [BugsnagStackframe frameFromDict:dict withImages:binaryImages];
    });
    
    NSDictionary *errorDict = crash[@ BSG_KSCrashField_Error];
    BugsnagError *error =
    [[BugsnagError alloc] initWithErrorClass:@"Crash handler crashed"
                                errorMessage:BSGParseErrorClass(errorDict, (id)errorDict[@ BSG_KSCrashField_Type])
                                   errorType:BSGErrorTypeCocoa
                                  stacktrace:stacktrace];
    
    BugsnagEvent *event = [self eventWithError:error context:nil diagnostics:recrashReport groupingHash:nil];
    event.handledState = [BugsnagHandledState handledStateWithSeverityReason:Signal];
    return event;
}

- (nullable BugsnagEvent *)eventWithError:(BugsnagError *)error
                                  context:(nullable NSString *)context
                              diagnostics:(nullable NSDictionary<NSString *, id> *)diagnostics
                             groupingHash:(nullable NSString *)groupingHash {
    
    BugsnagMetadata *metadata = [[BugsnagMetadata alloc] init];
    if (diagnostics) {
        [metadata addMetadata:(NSDictionary * _Nonnull)diagnostics toSection:BugsnagDiagnosticsKey];
    }
    [metadata addMetadata:self.apiKey withKey:BSGKeyApiKey toSection:BugsnagDiagnosticsKey];
    
    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:
                                   @"/System/Library/CoreServices/SystemVersion.plist"];
    
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState new];
    device.id           = DeviceId();
    device.manufacturer = @"Apple";
    device.osName       = systemVersion[@"ProductName"];
    device.osVersion    = systemVersion[@"ProductVersion"];
    
#if TARGET_OS_OSX || TARGET_OS_SIMULATOR || (defined(TARGET_OS_MACCATALYST) && TARGET_OS_MACCATALYST)
    device.model        = Sysctl("hw.model");
#else
    device.model        = Sysctl("hw.machine");
    device.modelNumber  = Sysctl("hw.model");
#endif
    
    BugsnagEvent *event =
    [[BugsnagEvent alloc] initWithApp:[BugsnagAppWithState new]
                               device:device
                         handledState:[BugsnagHandledState handledStateWithSeverityReason:HandledError]
                                 user:[[BugsnagUser alloc] init]
                             metadata:metadata
                          breadcrumbs:@[]
                               errors:@[error]
                              threads:@[]
                              session:nil];
    
    event.context = context;
    event.groupingHash = groupingHash;
    
    return event;
}

// MARK: Delivery

- (NSURLRequest *)requestForEvent:(nonnull BugsnagEvent *)event error:(NSError * __autoreleasing *)errorPtr {
    NSMutableDictionary *requestPayload = [NSMutableDictionary dictionary];
    requestPayload[BSGKeyEvents] = @[[event toJsonWithRedactedKeys:nil]];
    requestPayload[BSGKeyNotifier] = [[[BugsnagNotifier alloc] init] toDict];
    requestPayload[BSGKeyPayloadVersion] = EventPayloadVersion;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:requestPayload options:0 error:errorPtr];
    if (!data) {
        return nil;
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Content-Type"] = @"application/json";
    headers[BugsnagHTTPHeaderNameIntegrity] = BSGIntegrityHeaderValue(data);
    headers[BugsnagHTTPHeaderNameInternalError] = @"bugsnag-cocoa";
    headers[BugsnagHTTPHeaderNamePayloadVersion] = EventPayloadVersion;
    headers[BugsnagHTTPHeaderNameSentAt] = [BSG_RFC3339DateTool stringFromDate:[NSDate date]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.endpoint];
    request.allHTTPHeaderFields = headers;
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    
    return request;
}

- (void)sendEvent:(nonnull BugsnagEvent *)event {
    NSError *error = nil;
    NSURLRequest *request = [self requestForEvent:event error:&error];
    if (!request) {
        bsg_log_err(@"%@", error);
        return;
    }
    [[self.session dataTaskWithRequest:request] resume];
}

@end


// MARK: -

// Intentionally differs from +[BSG_KSSystemInfo deviceAndAppHash]
// See ROAD-1488
static NSString * DeviceId() {
    CC_SHA1_CTX ctx;
    CC_SHA1_Init(&ctx);

#if TARGET_OS_OSX
    char mac[6] = {0};
    bsg_kssysctl_getMacAddress(BSGKeyDefaultMacName, mac);
    CC_SHA1_Update(&ctx, mac, sizeof(mac));
#elif TARGET_OS_IOS || TARGET_OS_TV
    uuid_t uuid = {0};
    [[[UIDEVICE currentDevice] identifierForVendor] getUUIDBytes:uuid];
    CC_SHA1_Update(&ctx, uuid, sizeof(uuid));
#elif TARGET_OS_WATCH
    uuid_t uuid = {0};
    [[[WKInterfaceDevice currentDevice] identifierForVendor] getUUIDBytes:uuid];
    CC_SHA1_Update(&ctx, uuid, sizeof(uuid));
#else
#error Unsupported target platform
#endif
    
    const char *name = (NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName).UTF8String;
    if (name) {
        CC_SHA1_Update(&ctx, name, (CC_LONG)strlen(name));
    }
    
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(md, &ctx);
    
    char hex[2 * sizeof(md)];
    for (size_t i = 0; i < sizeof(md); i++) {
        static char lookup[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
        hex[i * 2 + 0] = lookup[(md[i] & 0xf0) >> 4];
        hex[i * 2 + 1] = lookup[(md[i] & 0x0f)];
    }
    return [[NSString alloc] initWithBytes:hex length:sizeof(hex) encoding:NSASCIIStringEncoding];
}

static NSString * Sysctl(const char *name) {
    char buffer[32] = {0};
    if (bsg_kssysctl_stringForName(name, buffer, sizeof buffer - 1)) {
        return @(buffer);
    } else {
        return nil;
    }
}
