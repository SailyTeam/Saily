//
//  BugsnagErrorTest.m
//  Tests
//
//  Created by Jamie Lynch on 08/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSGKeys.h"
#import "BugsnagError+Private.h"
#import "BugsnagStackframe.h"
#import "BugsnagThread+Private.h"

NSString *_Nonnull BSGParseErrorClass(NSDictionary *error, NSString *errorType);

NSString *BSGParseErrorMessage(NSDictionary *report, NSDictionary *error, NSString *errorType);

@interface BugsnagErrorTest : XCTestCase
@property NSDictionary *event;
@end

@implementation BugsnagErrorTest

- (void)setUp {
    NSDictionary *thread = @{
            @"current_thread": @YES,
            @"crashed": @YES,
            @"index": @4,
            @"state": @"TH_STATE_RUNNING",
            @"backtrace": @{
                    @"skipped": @0,
                    @"contents": @[
                            @{
                                    @"symbol_name": @"kscrashsentry_reportUserException",
                                    @"symbol_addr": @4491038467,
                                    @"instruction_addr": @4491038575,
                                    @"object_name": @"CrashProbeiOS",
                                    @"object_addr": @4490747904
                            }
                    ]
            }
    };
    NSDictionary *binaryImage = @{
            @"uuid": @"D0A41830-4FD2-3B02-A23B-0741AD4C7F52",
            @"image_vmaddr": @4294967296,
            @"image_addr": @4490747904,
            @"image_size": @483328,
            @"name": @"/Users/joesmith/foo",
    };
    self.event = @{
            @"crash": @{
                    @"error": @{
                            @"type": @"user",
                            @"user_reported": @{
                                    @"name": @"Foo Exception"
                            },
                            @"reason": @"Foo overload"
                    },
                    @"threads": @[thread],
            },
            @"binary_images": @[binaryImage]
    };
}

- (void)testErrorLoad {
    BugsnagThread *thread = [self findErrorReportingThread:self.event];
    BugsnagError *error = [[BugsnagError alloc] initWithKSCrashReport:self.event stacktrace:thread.stacktrace];
    XCTAssertEqualObjects(@"Foo Exception", error.errorClass);
    XCTAssertEqualObjects(@"Foo overload", error.errorMessage);
    XCTAssertEqual(BSGErrorTypeCocoa, error.type);

    XCTAssertEqual(1, [error.stacktrace count]);
    BugsnagStackframe *frame = error.stacktrace[0];
    XCTAssertEqualObjects(@"kscrashsentry_reportUserException", frame.method);
    XCTAssertEqualObjects(@"/Users/joesmith/foo", frame.machoFile);
    XCTAssertEqualObjects(@"D0A41830-4FD2-3B02-A23B-0741AD4C7F52", frame.machoUuid);
}

- (void)testErrorFromInvalidJson {
    BugsnagError *error;
    
    error = [BugsnagError errorFromJson:@{
        @"stacktrace": [NSNull null],
    }];
    XCTAssertEqualObjects(error.stacktrace, @[]);
    
    error = [BugsnagError errorFromJson:@{
        @"stacktrace": @{@"foo": @"bar"},
    }];
    XCTAssertEqualObjects(error.stacktrace, @[]);
}

- (void)testToDictionary {
    BugsnagThread *thread = [self findErrorReportingThread:self.event];
    BugsnagError *error = [[BugsnagError alloc] initWithKSCrashReport:self.event stacktrace:thread.stacktrace];
    NSDictionary *dict = [error toDictionary];
    XCTAssertEqualObjects(@"Foo Exception", dict[@"errorClass"]);
    XCTAssertEqualObjects(@"Foo overload", dict[@"message"]);
    XCTAssertEqualObjects(@"cocoa", dict[@"type"]);

    XCTAssertEqual(1, [dict[@"stacktrace"] count]);
    NSDictionary *frame = dict[@"stacktrace"][0];
    XCTAssertEqualObjects(@"kscrashsentry_reportUserException", frame[@"method"]);
    XCTAssertEqualObjects(@"D0A41830-4FD2-3B02-A23B-0741AD4C7F52", frame[@"machoUUID"]);
    XCTAssertEqualObjects(@"/Users/joesmith/foo", frame[@"machoFile"]);
}

- (BugsnagThread *)findErrorReportingThread:(NSDictionary *)event {
    NSArray *binaryImages = event[@"binary_images"];
    NSArray *threadDict = [event valueForKeyPath:@"crash.threads"];
    NSArray<BugsnagThread *> *threads = [BugsnagThread threadsFromArray:threadDict
                                                           binaryImages:binaryImages];
    for (BugsnagThread *thread in threads) {
        if (thread.errorReportingThread) {
            return thread;
        }
    }
    return nil;
}

- (void)testErrorClassParse {
    XCTAssertEqualObjects(@"foo", BSGParseErrorClass(@{@"cpp_exception": @{@"name": @"foo"}}, @"cpp_exception"));
    XCTAssertEqualObjects(@"bar", BSGParseErrorClass(@{@"mach": @{@"exception_name": @"bar"}}, @"mach"));
    XCTAssertEqualObjects(@"wham", BSGParseErrorClass(@{@"signal": @{@"name": @"wham"}}, @"signal"));
    XCTAssertEqualObjects(@"zed", BSGParseErrorClass(@{@"nsexception": @{@"name": @"zed"}}, @"nsexception"));
    XCTAssertEqualObjects(@"ooh", BSGParseErrorClass(@{@"user_reported": @{@"name": @"ooh"}}, @"user"));
    XCTAssertEqualObjects(@"Exception", BSGParseErrorClass(@{}, @"some-val"));
}

- (void)testErrorMessageParse {
    XCTAssertEqualObjects(@"", BSGParseErrorMessage(@{}, @{}, @""));
    XCTAssertEqualObjects(@"foo", BSGParseErrorMessage(@{}, @{@"reason": @"foo"}, @""));
}

- (void)testStacktraceOverride {
    BugsnagThread *thread = [self findErrorReportingThread:self.event];
    BugsnagError *error = [[BugsnagError alloc] initWithKSCrashReport:self.event stacktrace:thread.stacktrace];
    XCTAssertNotNil(error.stacktrace);
    XCTAssertEqual(1, error.stacktrace.count);
    error.stacktrace = @[];
    XCTAssertEqual(0, error.stacktrace.count);
}

- (void)testUpdateWithCrashInfoMessage {
    BugsnagError *error = [[BugsnagError alloc] initWithErrorClass:@"" errorMessage:@"" errorType:BSGErrorTypeCocoa stacktrace:nil];
    
    // Swift fatal errors with a message.
    // The errorClass and errorMessage should be overwritten with values extracted from the crash info message.
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"Assertion failed: This should NEVER happen: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, @"This should NEVER happen");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"assertion failed: This should NEVER happen: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"assertion failed");
    XCTAssertEqualObjects(error.errorMessage, @"This should NEVER happen");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"Fatal error: A suffusion of yellow: file calc.swift, line 5\n"];
    XCTAssertEqualObjects(error.errorClass, @"Fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"A suffusion of yellow");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"fatal error: This should NEVER happen: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"This should NEVER happen");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"Fatal error: Unexpectedly found nil while unwrapping an Optional value\n"];
    XCTAssertEqualObjects(error.errorClass, @"Fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"Unexpectedly found nil while unwrapping an Optional value");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"Precondition failed:   : strange formatting 😱::: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Precondition failed");
    XCTAssertEqualObjects(error.errorMessage, @"  : strange formatting 😱::");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"precondition failed:   : strange formatting 😱::: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"precondition failed");
    XCTAssertEqualObjects(error.errorMessage, @"  : strange formatting 😱::");
    
    // Swift fatal errors without a message.
    // The errorClass should be overwritten but the errorMessage left as-is.
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"Assertion failed: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, nil);
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"Assertion failed: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"Fatal error: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"Precondition failed: file bugsnag_example/AnotherClass.swift, line 24\n"];
    XCTAssertEqualObjects(error.errorClass, @"Precondition failed");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    // Non-matching crash info messages.
    // The errorClass should not be overwritten, the errorMessage should be overwritten if it was previously empty / nil.
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"Assertion failed: This should NEVER happen: file bugsnag_example/AnotherClass.swift, line 24\njunk"];
    XCTAssertEqualObjects(error.errorClass, nil,);
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    error.errorClass = @"Expected error class";
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"BUG IN CLIENT OF LIBDISPATCH: dispatch_sync called on queue already owned by current thread"];
    XCTAssertEqualObjects(error.errorClass, @"Expected error class");
    
    error.errorClass = @"Expected error class";
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"BUG IN CLIENT OF LIBDISPATCH: dispatch_sync called on queue already owned by current thread"];
    XCTAssertEqualObjects(error.errorClass, @"Expected error class",);
    XCTAssertEqualObjects(error.errorMessage, @"BUG IN CLIENT OF LIBDISPATCH: dispatch_sync called on queue already owned by current thread");
    
    error.errorClass = @"Expected error class";
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@""];
    XCTAssertEqualObjects(error.errorClass, @"Expected error class");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message",);
    
    error.errorClass = @"Expected error class";
    error.errorMessage = @"Expected message";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [error updateWithCrashInfoMessage:nil];
#pragma clang diagnostic pop
    XCTAssertEqualObjects(error.errorClass, @"Expected error class",);
    XCTAssertEqualObjects(error.errorMessage, @"Expected message",);
}

- (void)testUpdateWithCrashInfoMessage_Swift54 {
    BugsnagError *error = [[BugsnagError alloc] initWithErrorClass:@"" errorMessage:@"" errorType:BSGErrorTypeCocoa stacktrace:nil];
    
    // Swift fatal errors with a message.
    // The errorClass and errorMessage should be overwritten with values extracted from the crash info message.
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Assertion failed: This should NEVER happen\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, @"This should NEVER happen");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"calc.swift:5: Fatal error: A suffusion of yellow\n"];
    XCTAssertEqualObjects(error.errorClass, @"Fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"A suffusion of yellow");
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Precondition failed:   : strange formatting 😱::\n"];
    XCTAssertEqualObjects(error.errorClass, @"Precondition failed");
    XCTAssertEqualObjects(error.errorMessage, @"  : strange formatting 😱::");
    
    // Swift fatal errors without a message.
    // The errorClass should be overwritten but the errorMessage left as-is.
    
    error.errorClass = nil;
    error.errorMessage = nil;
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Assertion failed\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, nil);
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Assertion failed\n"];
    XCTAssertEqualObjects(error.errorClass, @"Assertion failed");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Fatal error\n"];
    XCTAssertEqualObjects(error.errorClass, @"Fatal error");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
    
    error.errorClass = nil;
    error.errorMessage = @"Expected message";
    [error updateWithCrashInfoMessage:@"bugsnag_example/AnotherClass.swift:24: Precondition failed\n"];
    XCTAssertEqualObjects(error.errorClass, @"Precondition failed");
    XCTAssertEqualObjects(error.errorMessage, @"Expected message");
}

@end
