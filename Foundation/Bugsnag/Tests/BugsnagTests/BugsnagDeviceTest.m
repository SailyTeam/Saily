//
//  BugsnagDeviceTest.m
//  Tests
//
//  Created by Jamie Lynch on 02/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSG_KSSystemInfo.h"
#import "BugsnagDevice+Private.h"
#import "BugsnagDeviceWithState+Private.h"

@interface BugsnagDeviceTest : XCTestCase
@property NSDictionary *data;
@end

@implementation BugsnagDeviceTest

- (void)setUp {
    [super setUp];
    self.data = @{
            @"system": @{
                    @"model": @"iPhone 6",
                    @"machine": @"x86_64",
                    @"system_name": @"iPhone OS",
                    @"system_version": @"8.1",
                    @"os_version": @"14B25",
                    @"clang_version": @"10.0.0 (clang-1000.11.45.5)",
                    @"jailbroken": @YES,
                    @"memory": @{
                            @"size": @15065522176,
                            @"free": @742920192
                    },
                    @"disk": @{
                        @"free": @1234567
                    },
                    @"device_app_hash": @"123"
            },
            @"report": @{
                    @"timestamp": @"2014-12-02T01:56:13Z"
            },
            @"user": @{
                    @"state": @{
                            @"deviceState": @{
                                    @"orientation": @"portrait"
                            }
                    }
            }
    };
}

- (void)testDevice {
    BugsnagDevice *device = [BugsnagDevice deviceWithKSCrashReport:self.data];

    // verify stateless fields
    XCTAssertTrue(device.jailbroken);
    XCTAssertEqualObjects(@"123", device.id);
    XCTAssertNotNil(device.locale);
    XCTAssertEqualObjects(@"Apple", device.manufacturer);
    XCTAssertEqualObjects(@"x86_64", device.model);
    XCTAssertEqualObjects(@"iPhone 6", device.modelNumber);
    XCTAssertEqualObjects(@"iPhone OS", device.osName);
    XCTAssertEqualObjects(@"8.1", device.osVersion);
    XCTAssertEqualObjects(@15065522176, device.totalMemory);
    NSDictionary *runtimeVersions = @{
            @"osBuild": @"14B25",
            @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
    };
    XCTAssertEqualObjects(runtimeVersions, device.runtimeVersions);
}

- (void)testDeviceWithState {
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceWithKSCrashReport:self.data];

    // verify stateless fields
    XCTAssertTrue(device.jailbroken);
    XCTAssertEqualObjects(@"123", device.id);
    XCTAssertNotNil(device.locale);
    XCTAssertEqualObjects(@"Apple", device.manufacturer);
    XCTAssertEqualObjects(@"x86_64", device.model);
    XCTAssertEqualObjects(@"iPhone 6", device.modelNumber);
    XCTAssertEqualObjects(@"iPhone OS", device.osName);
    XCTAssertEqualObjects(@"8.1", device.osVersion);
    XCTAssertEqualObjects(@15065522176, device.totalMemory);
    NSDictionary *runtimeVersions = @{
            @"osBuild": @"14B25",
            @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
    };
    XCTAssertEqualObjects(runtimeVersions, device.runtimeVersions);

    // verify stateful fields
    XCTAssertGreaterThan(device.freeDisk.longLongValue, 0);
    XCTAssertEqualObjects(@742920192, device.freeMemory);
    XCTAssertEqualObjects(@"portrait", device.orientation);

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    XCTAssertEqualObjects([formatter dateFromString:@"2014-12-02T01:56:13Z"], device.time);
}

- (void)testDeviceWithRealSystemInfo {
    NSDictionary *systemInfo = [BSG_KSSystemInfo systemInfo];
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceWithKSCrashReport:@{@"system": systemInfo}];
    XCTAssertLessThan(device.freeMemory.unsignedLongLongValue, device.totalMemory.unsignedLongLongValue);
}

- (void)testDeviceToDict {
    BugsnagDevice *device = [BugsnagDevice deviceWithKSCrashReport:self.data];
    device.locale = @"en-US";
    NSDictionary *dict = [device toDictionary];

    // verify stateless fields
    XCTAssertTrue(dict[@"jailbroken"]);
    XCTAssertEqualObjects(@"123", dict[@"id"]);
    XCTAssertEqualObjects(@"en-US", dict[@"locale"]);
    XCTAssertEqualObjects(@"Apple", dict[@"manufacturer"]);
    XCTAssertEqualObjects(@"x86_64", dict[@"model"]);
    XCTAssertEqualObjects(@"iPhone 6", dict[@"modelNumber"]);
    XCTAssertEqualObjects(@"iPhone OS", dict[@"osName"]);
    XCTAssertEqualObjects(@"8.1", dict[@"osVersion"]);
    XCTAssertEqualObjects(@15065522176, dict[@"totalMemory"]);

    NSDictionary *runtimeVersions = @{
            @"osBuild": @"14B25",
            @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
    };
    XCTAssertEqualObjects(runtimeVersions, dict[@"runtimeVersions"]);
}

- (void)testDeviceWithStateToDict {
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceWithKSCrashReport:self.data];
    device.locale = @"en-US";
    NSDictionary *dict = [device toDictionary];

    XCTAssertTrue(dict[@"jailbroken"]);
    XCTAssertEqualObjects(@"123", dict[@"id"]);
    XCTAssertEqualObjects(@"en-US", dict[@"locale"]);
    XCTAssertEqualObjects(@"Apple", dict[@"manufacturer"]);
    XCTAssertEqualObjects(@"x86_64", dict[@"model"]);
    XCTAssertEqualObjects(@"iPhone 6", dict[@"modelNumber"]);
    XCTAssertEqualObjects(@"iPhone OS", dict[@"osName"]);
    XCTAssertEqualObjects(@"8.1", dict[@"osVersion"]);
    XCTAssertEqualObjects(@15065522176, dict[@"totalMemory"]);

    NSDictionary *runtimeVersions = @{
            @"osBuild": @"14B25",
            @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
    };
    XCTAssertEqualObjects(runtimeVersions, dict[@"runtimeVersions"]);

    // verify stateless fields
    XCTAssertEqualObjects(@"portrait", dict[@"orientation"]);
    XCTAssertTrue(dict[@"freeDisk"] > 0);
    XCTAssertEqualObjects(@742920192, dict[@"freeMemory"]);

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    XCTAssertEqualObjects([formatter dateFromString:@"2014-12-02T01:56:13Z"], device.time);
}

- (void)testDeviceRuntimeInfoAppended {
    BugsnagDevice *device = [BugsnagDevice deviceWithKSCrashReport:self.data];
    XCTAssertEqual(2, [device.runtimeVersions count]);
    XCTAssertEqualObjects(@"14B25", device.runtimeVersions[@"osBuild"]);
    XCTAssertEqualObjects(@"10.0.0 (clang-1000.11.45.5)", device.runtimeVersions[@"clangVersion"]);

    [device appendRuntimeInfo:@{@"foo": @"bar"}];
    XCTAssertEqual(3, [device.runtimeVersions count]);
    XCTAssertEqualObjects(@"14B25", device.runtimeVersions[@"osBuild"]);
    XCTAssertEqualObjects(@"10.0.0 (clang-1000.11.45.5)", device.runtimeVersions[@"clangVersion"]);
    XCTAssertEqualObjects(@"bar", device.runtimeVersions[@"foo"]);
}

- (void)testDeviceFromJson {
    NSDictionary *json = @{
            @"jailbroken": @YES,
            @"id": @"123",
            @"locale": @"en-US",
            @"manufacturer": @"Apple",
            @"model": @"x86_64",
            @"modelNumber": @"iPhone 6",
            @"osName": @"iPhone OS",
            @"osVersion": @"8.1",
            @"totalMemory": @15065522176,
            @"runtimeVersions": @{
                    @"osBuild": @"14B25",
                    @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
            },
            @"freeDisk": @509234098,
            @"freeMemory": @742920192,
            @"orientation": @"portrait",
            @"time": @"2014-12-02T01:56:13Z"
    };
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceFromJson:json];
    XCTAssertNotNil(device);

    // verify stateless fields
    XCTAssertTrue(device.jailbroken);
    XCTAssertEqualObjects(@"123", device.id);
    XCTAssertEqualObjects(@"en-US", device.locale);
    XCTAssertEqualObjects(@"Apple", device.manufacturer);
    XCTAssertEqualObjects(@"x86_64", device.model);
    XCTAssertEqualObjects(@"iPhone 6", device.modelNumber);
    XCTAssertEqualObjects(@"iPhone OS", device.osName);
    XCTAssertEqualObjects(@"8.1", device.osVersion);
    XCTAssertEqualObjects(@15065522176, device.totalMemory);
    NSDictionary *runtimeVersions = @{
            @"osBuild": @"14B25",
            @"clangVersion": @"10.0.0 (clang-1000.11.45.5)"
    };
    XCTAssertEqualObjects(runtimeVersions, device.runtimeVersions);

    // verify stateful fields
    XCTAssertEqualObjects(@509234098, device.freeDisk);
    XCTAssertEqualObjects(@742920192, device.freeMemory);
    XCTAssertEqualObjects(@"portrait", device.orientation);

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    XCTAssertEqualObjects([formatter dateFromString:@"2014-12-02T01:56:13Z"], device.time);
}

@end
