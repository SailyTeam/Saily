//
//  BugsnagStackframeTest.m
//  Tests
//
//  Created by Jamie Lynch on 06/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSG_KSMachHeaders.h"
#import "BugsnagStackframe+Private.h"

@interface BugsnagStackframeTest : XCTestCase
@property NSDictionary *frameDict;
@property NSArray *binaryImages;
@end

@implementation BugsnagStackframeTest

- (void)setUp {
    self.frameDict = @{
            @"symbol_addr": @0x10b574fa0,
            @"instruction_addr": @0x10b5756bf,
            @"object_addr": @0x10b54b000,
            @"object_name": @"/Library/bar/Bugsnag.h",
            @"symbol_name": @"-[BugsnagClient notify:handledState:block:]",
    };
    self.binaryImages = @[@{
            @"image_addr": @0x10b54b000,
            @"image_vmaddr": @0x102340922,
            @"uuid": @"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F",
            @"name": @"/Users/foo/Bugsnag.h",
    }];
}

- (void)testStackframeFromDict {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromDict:self.frameDict withImages:self.binaryImages];
    XCTAssertEqualObjects(@"-[BugsnagClient notify:handledState:block:]", frame.method);
    XCTAssertEqualObjects(@"/Users/foo/Bugsnag.h", frame.machoFile);
    XCTAssertEqualObjects(@"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F", frame.machoUuid);
    XCTAssertEqualObjects(@0x102340922, frame.machoVmAddress);
    XCTAssertEqualObjects(@0x10b574fa0, frame.symbolAddress);
    XCTAssertEqualObjects(@0x10b54b000, frame.machoLoadAddress);
    XCTAssertEqualObjects(@0x10b5756bf, frame.frameAddress);
    XCTAssertNil(frame.type);
    XCTAssertFalse(frame.isPc);
    XCTAssertFalse(frame.isLr);
}

- (void)testStackframeToDict {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromDict:self.frameDict withImages:self.binaryImages];
    NSDictionary *dict = [frame toDictionary];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dict]);
    XCTAssertEqualObjects(@"-[BugsnagClient notify:handledState:block:]", dict[@"method"]);
    XCTAssertEqualObjects(@"/Users/foo/Bugsnag.h", dict[@"machoFile"]);
    XCTAssertEqualObjects(@"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F", dict[@"machoUUID"]);
    XCTAssertEqualObjects(@"0x102340922", dict[@"machoVMAddress"]);
    XCTAssertEqualObjects(@"0x10b574fa0", dict[@"symbolAddress"]);
    XCTAssertEqualObjects(@"0x10b54b000", dict[@"machoLoadAddress"]);
    XCTAssertEqualObjects(@"0x10b5756bf", dict[@"frameAddress"]);
    XCTAssertNil(frame.type);
    XCTAssertNil(dict[@"isPC"]);
    XCTAssertNil(dict[@"isLR"]);
}

- (void)testStackframeFromJson {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromJson:@{
        @"columnNumber":        @72,
        @"frameAddress":        @"0x10b5756bf",
        @"inProject":           @YES,
        @"isLR":                @NO,
        @"isPC":                @YES,
        @"lineNumber":          @42,
        @"machoFile":           @"/Users/foo/Bugsnag.h",
        @"machoLoadAddress":    @"0x10b54b000",
        @"machoUUID":           @"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F",
        @"machoVMAddress":      @"0x102340922",
        @"method":              @"-[BugsnagClient notify:handledState:block:]",
        @"symbolAddress":       @"0x10b574fa0",
        @"type":                @"cocoa",
    }];
    XCTAssertEqual(frame.isLr, NO);
    XCTAssertEqual(frame.isPc, YES);
    XCTAssertEqualObjects(frame.columnNumber,       @72);
    XCTAssertEqualObjects(frame.frameAddress,       @0x10b5756bf);
    XCTAssertEqualObjects(frame.inProject,          @YES);
    XCTAssertEqualObjects(frame.lineNumber,         @42);
    XCTAssertEqualObjects(frame.machoFile,          @"/Users/foo/Bugsnag.h");
    XCTAssertEqualObjects(frame.machoLoadAddress,   @0x10b54b000);
    XCTAssertEqualObjects(frame.machoUuid,          @"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F");
    XCTAssertEqualObjects(frame.machoVmAddress,     @0x102340922);
    XCTAssertEqualObjects(frame.method,             @"-[BugsnagClient notify:handledState:block:]");
    XCTAssertEqualObjects(frame.symbolAddress,      @0x10b574fa0);
    XCTAssertEqualObjects(frame.type,               BugsnagStackframeTypeCocoa);
}

- (void)testStackframeFromJsonWithNullValues {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromJson:@{
        @"columnNumber":        [NSNull null],
        @"frameAddress":        [NSNull null],
        @"inProject":           [NSNull null],
        @"isLR":                [NSNull null],
        @"isPC":                [NSNull null],
        @"lineNumber":          [NSNull null],
        @"machoFile":           [NSNull null],
        @"machoLoadAddress":    [NSNull null],
        @"machoUUID":           [NSNull null],
        @"machoVMAddress":      [NSNull null],
        @"method":              [NSNull null],
        @"symbolAddress":       [NSNull null],
        @"type":                [NSNull null],
    }];
    XCTAssertEqual(frame.isLr, NO);
    XCTAssertEqual(frame.isPc, NO);
    XCTAssertNil(frame.columnNumber);
    XCTAssertNil(frame.frameAddress);
    XCTAssertNil(frame.inProject);
    XCTAssertNil(frame.lineNumber);
    XCTAssertNil(frame.machoFile);
    XCTAssertNil(frame.machoLoadAddress);
    XCTAssertNil(frame.machoUuid);
    XCTAssertNil(frame.machoVmAddress);
    XCTAssertNil(frame.method);
    XCTAssertNil(frame.symbolAddress);
    XCTAssertNil(frame.type);
}

- (void)testStackframeFromJsonWithoutType {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromJson:@{}];
    XCTAssertNil(frame.type);
}

- (void)testStackframeToDictPcLr {
    BugsnagStackframe *frame = [BugsnagStackframe frameFromDict:self.frameDict withImages:self.binaryImages];
    frame.isPc = true;
    frame.isLr = true;
    NSDictionary *dict = [frame toDictionary];
    XCTAssertTrue(dict[@"isPC"]);
    XCTAssertTrue(dict[@"isLR"]);
}

- (void)testStackframeBools {
    NSDictionary *dict = @{
            @"symbol_addr": @0x10b574fa0,
            @"instruction_addr": @0x10b5756bf,
            @"object_addr": @0x10b54b000,
            @"object_name": @"/Users/foo/Bugsnag.h",
            @"symbol_name": @"-[BugsnagClient notify:handledState:block:]",
            @"isPC": @YES,
            @"isLR": @NO
    };
    BugsnagStackframe *frame = [BugsnagStackframe frameFromDict:dict withImages:self.binaryImages];
    XCTAssertTrue(frame.isPc);
    XCTAssertFalse(frame.isLr);
}

- (void)testInvalidFrame {
    // Sample 2nd frame from EXC_BREAKPOINT mach exception
    NSDictionary *dict = @{@"instruction_addr": @0x232e968186bc223c, @"isLR": @YES};
    BugsnagStackframe *frame = [BugsnagStackframe frameFromDict:dict withImages:@[]];
    XCTAssertNil(frame);
    
    // Sample bottom frame from NSException on macOS
    XCTAssertNil([BugsnagStackframe frameFromDict:@{@"instruction_addr": @0x1} withImages:@[]]);
}

#define AssertStackframeValues(stackframe_, machoFile_, frameAddress_, method_) \
    XCTAssertEqualObjects(stackframe_.method, method_); \
    XCTAssertEqualObjects(stackframe_.machoFile, machoFile_); \
    XCTAssertEqualObjects(stackframe_.frameAddress, @(frameAddress_)); \
    XCTAssertNil(stackframe_.type);

- (void)testDummyCallStackSymbols {
    bsg_mach_headers_initialize(); // Prevent symbolication
    
    NSArray<BugsnagStackframe *> *stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:@[]];
    XCTAssertEqual(stackframes.count, 0);
    
    stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:@[
        @"",
        @"1",
        @"ReactNativeTest",
        @"0x0000000000000000",
        @"__invoking___ + 140"]];
    XCTAssertEqual(stackframes.count, 0, @"Invalid stack frame strings should be ignored");
    
    stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:@[
        @"0   ReactNativeTest                     0x000000010fda7f1b RCTJSErrorFromCodeMessageAndNSError + 79",
        @"1   ReactNativeTest                     0x000000010fd76897 __41-[RCTModuleMethod processMethodSignature]_block_invoke_2.103 + 97",
        @"2   ReactNativeTest                     0x000000010fccd9c3 -[BenCrash asyncReject:rejecter:] + 106",
        @"3   CoreFoundation                      0x00007fff23e44dec __invoking___ + 140",
        @"4   CoreFoundation                      0x00007fff23e41fd1 -[NSInvocation invoke] + 321",
        @"5   CoreFoundation                      0x00007fff23e422a4 -[NSInvocation invokeWithTarget:] + 68",
        @"6  ReactNativeTest                     0x000000010fd76eae -[RCTModuleMethod invokeWithBridge:module:arguments:] + 578",
        @"7 ReactNativeTest                     0x000000010fd79138 _ZN8facebook5reactL11invokeInnerEP9RCTBridgeP13RCTModuleDatajRKN5folly7dynamicE + 246"]];
    
    AssertStackframeValues(stackframes[0], @"ReactNativeTest",  0x000000010fda7f1b, @"RCTJSErrorFromCodeMessageAndNSError");
    AssertStackframeValues(stackframes[1], @"ReactNativeTest",  0x000000010fd76897, @"__41-[RCTModuleMethod processMethodSignature]_block_invoke_2.103");
    AssertStackframeValues(stackframes[2], @"ReactNativeTest",  0x000000010fccd9c3, @"-[BenCrash asyncReject:rejecter:]");
    AssertStackframeValues(stackframes[3], @"CoreFoundation",   0x00007fff23e44dec, @"__invoking___");
    AssertStackframeValues(stackframes[4], @"CoreFoundation",   0x00007fff23e41fd1, @"-[NSInvocation invoke]");
    AssertStackframeValues(stackframes[5], @"CoreFoundation",   0x00007fff23e422a4, @"-[NSInvocation invokeWithTarget:]");
    AssertStackframeValues(stackframes[6], @"ReactNativeTest",  0x000000010fd76eae, @"-[RCTModuleMethod invokeWithBridge:module:arguments:]");
    AssertStackframeValues(stackframes[7], @"ReactNativeTest",  0x000000010fd79138, @"_ZN8facebook5reactL11invokeInnerEP9RCTBridgeP13RCTModuleDatajRKN5folly7dynamicE");
    
    stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:@[
        @"0   ReactNativeTest                     0x000000010fda7f1b",
        @"1   ReactNativeTest                     0x000000010fd76897",
        @"2   ReactNativeTest                     0x000000010fccd9c3",
        @"3   CoreFoundation                      0x00007fff23e44dec",
        @"4   CoreFoundation                      0x00007fff23e41fd1",
        @"5   CoreFoundation                      0x00007fff23e422a4",
        @"6   ReactNativeTest                     0x000000010fd76eae",
        @"7   ReactNative App                     0x000000010fd79138"]];
    
    AssertStackframeValues(stackframes[0], @"ReactNativeTest",  0x000000010fda7f1b, @"0x000000010fda7f1b");
    AssertStackframeValues(stackframes[1], @"ReactNativeTest",  0x000000010fd76897, @"0x000000010fd76897");
    AssertStackframeValues(stackframes[2], @"ReactNativeTest",  0x000000010fccd9c3, @"0x000000010fccd9c3");
    AssertStackframeValues(stackframes[3], @"CoreFoundation",   0x00007fff23e44dec, @"0x00007fff23e44dec");
    AssertStackframeValues(stackframes[4], @"CoreFoundation",   0x00007fff23e41fd1, @"0x00007fff23e41fd1");
    AssertStackframeValues(stackframes[5], @"CoreFoundation",   0x00007fff23e422a4, @"0x00007fff23e422a4");
    AssertStackframeValues(stackframes[6], @"ReactNativeTest",  0x000000010fd76eae, @"0x000000010fd76eae");
    AssertStackframeValues(stackframes[7], @"ReactNative App",  0x000000010fd79138, @"0x000000010fd79138");
    
    stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:@[
        @"57  ???                                 0x0000000104eb90f4 0x0 + 4377514228",
        @"58  ???                                 0x1855800000000000 0x0 + 1753448367419031552"]];
    
    AssertStackframeValues(stackframes[0], @"???",  0x0000000104eb90f4, @"0x0");
    AssertStackframeValues(stackframes[1], @"???",  0x1855800000000000, @"0x0");
}

- (void)testRealCallStackSymbols {
    bsg_mach_headers_initialize();
    bsg_mach_headers_get_images(); // Ensure call stack can be symbolicated
    
    NSArray<NSString *> *callStackSymbols = [NSThread callStackSymbols];
    NSArray<BugsnagStackframe *> *stackframes = [BugsnagStackframe stackframesWithCallStackSymbols:callStackSymbols];
    XCTAssertEqual(stackframes.count, callStackSymbols.count, @"All valid stack frame strings should be parsed");
    BOOL __block didSeeMain = NO;
    [stackframes enumerateObjectsUsingBlock:^(BugsnagStackframe *stackframe, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(stackframe.frameAddress);
        XCTAssertNotNil(stackframe.machoFile);
        XCTAssertNotNil(stackframe.method);
        XCTAssertTrue([callStackSymbols[idx] containsString:stackframe.method]);
        if (stackframe.frameAddress.unsignedLongLongValue < 0x1000) {
            // Stack frames with invalid instruction addresses cannot be resolved to an image or symbol
            return;
        }
#if TARGET_OS_SIMULATOR
        if ([callStackSymbols[idx] containsString:@"0x0 + "]) {
            // This frame is not in any known image
            return;
        }
#endif
        XCTAssertNotNil(stackframe.machoUuid);
        XCTAssertNotNil(stackframe.machoVmAddress);
        XCTAssertNotNil(stackframe.machoLoadAddress);
#if TARGET_OS_SIMULATOR
        if (didSeeMain) {
            // Stack frames below main are problematic to symbolicate, so skip those checks
            return;
        }
#endif
        [stackframe symbolicateIfNeeded];
        XCTAssertNotNil(stackframe.symbolAddress);
        XCTAssertNil(stackframe.type);
        XCTAssertTrue([callStackSymbols[idx] containsString:stackframe.method] ||
                      // Sometimes we do a better job at symbolication (-:
                      [callStackSymbols[idx] containsString:@"???"] ||
                      // But sometimes the best we can do is not great
                      [stackframe.method isEqualToString:@"<redacted>"] ||
                      // callStackSymbols contains the wrong symbol name - "__copy_helper_block_e8_32s"
                      // lldb agrees that the symbol should be "__RunTests_block_invoke_2"
                      [stackframe.method isEqualToString:@"__RunTests_block_invoke_2"]);
        
        if ([stackframe.method isEqualToString:@"main"]) {
            didSeeMain = YES;
        }
    }];
}

@end
