//
//  BSGStorageMigratorV0V1Tests.m
//  Bugsnag-iOSTests
//
//  Created by Karl Stenerud on 07.01.21.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BSGStorageMigratorV0V1.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagTestConstants.h"

@interface BSGStorageMigratorV0V1Tests : XCTestCase

@end

@implementation BSGStorageMigratorV0V1Tests

- (NSString *)getCachesDir {
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([dirs count] == 0) {
        XCTFail(@"Could not locate directory path for NSCachesDirectory.");
        return nil;
    }

    if ([dirs[0] length] == 0) {
        XCTFail(@"Directory path for NSCachesDirectory is empty!");
        return nil;
    }

    return dirs[0];
}

- (NSString *)getV1RootDir {
#if TARGET_OS_TV
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
#else
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
#endif
    if ([dirs count] == 0) {
        XCTFail(@"Could not locate directory path for NSApplicationSupportDirectory.");
        return nil;
    }

    if ([dirs[0] length] == 0) {
        XCTFail(@"Directory path for NSApplicationSupportDirectory is empty!");
        return nil;
    }

    return [NSString stringWithFormat:@"%@/com.bugsnag.Bugsnag/%@/v1",
            dirs[0],
            NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName];
}

- (NSDictionary *)getDirs {
    NSString *c = [self getCachesDir];
    NSString *r = [self getV1RootDir];

    return @{
        [c stringByAppendingPathComponent:@"bugsnag/breadcrumbs"]: [r stringByAppendingPathComponent:@"breadcrumbs"],
        [c stringByAppendingPathComponent:@"Sessions/xctest"]: [r stringByAppendingPathComponent:@"sessions"],
        [c stringByAppendingPathComponent:@"KSCrashReports/xctest"]: [r stringByAppendingPathComponent:@"KSCrashReports"],
    };
}

- (NSDictionary *)getFiles {
    NSString *c = [self getCachesDir];
    NSString *r = [self getV1RootDir];

    return @{
        [c stringByAppendingPathComponent:@"bugsnag_handled_crash.txt"]: [r stringByAppendingPathComponent:@"bugsnag_handled_crash.txt"],
        [c stringByAppendingPathComponent:@"bugsnag/config.json"]: [r stringByAppendingPathComponent:@"config.json"],
        [c stringByAppendingPathComponent:@"bugsnag/metadata.json"]: [r stringByAppendingPathComponent:@"metadata.json"],
        [c stringByAppendingPathComponent:@"bugsnag/state.json"]: [r stringByAppendingPathComponent:@"state.json"],
        [c stringByAppendingPathComponent:@"bugsnag/state/system_state.json"]: [r stringByAppendingPathComponent:@"system_state.json"],
    };
}

- (void)setUp {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *cachesPath = [self getCachesDir];
    NSError *err = nil;

    // Test case app data is kept in a globally shared location, so make sure it's cleared.
    [fm removeItemAtPath:[self getV1RootDir] error:nil];
    for(NSString* path in [self getFiles]) {
        [fm removeItemAtPath:path error:nil];
    }
    [fm removeItemAtPath:[cachesPath stringByAppendingPathComponent:@"bugsnag"] error:nil];
    [fm removeItemAtPath:[cachesPath stringByAppendingPathComponent:@"Sessions"] error:nil];
    [fm removeItemAtPath:[cachesPath stringByAppendingPathComponent:@"KSCrashReports"] error:nil];
    [fm removeItemAtPath:[cachesPath stringByAppendingPathComponent:@"bsg_kvstore"] error:nil];

    // Now copy the faked app data across from the test fixture data.
    NSString *srcPath = [[bundle resourcePath] stringByAppendingPathComponent:@"v0_files/Caches"];
    for(NSString *file in [fm contentsOfDirectoryAtPath:srcPath error:&err]) {
        if (![fm copyItemAtPath:[srcPath stringByAppendingPathComponent:file]
                         toPath:[cachesPath stringByAppendingPathComponent:file]
                          error:&err]) {
            XCTFail(@"%@", err);
        }
    }
    if(err != nil) {
        XCTFail(@"%@", err);
    }
}

- (void)testMigrateFiles {
    NSDictionary *dirs = [self getDirs];
    NSDictionary *files = [self getFiles];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    // Make sure pre-state is as we expect.
    for(NSString *path in files) {
        if(![fm fileExistsAtPath:path isDirectory:&isDir]) {
            XCTFail(@"Expected path to exist: %@", path);
        }
        if(isDir) {
            XCTFail(@"Expected a file: %@", path);
        }
    }
    for(NSString *path in dirs) {
        if(![fm fileExistsAtPath:path isDirectory:&isDir]) {
            XCTFail(@"Expected path to exist: %@", path);
        }
        if(!isDir) {
            XCTFail(@"Expected a directory: %@", path);
        }
    }

    // Migrate and check.
    [BSGStorageMigratorV0V1 migrate];
    [self postMigrateCheck];

    // Make sure it's idempotent.
    [BSGStorageMigratorV0V1 migrate];
    [BSGStorageMigratorV0V1 migrate];
    [BSGStorageMigratorV0V1 migrate];
    [BSGStorageMigratorV0V1 migrate];
    [BSGStorageMigratorV0V1 migrate];
    [BSGStorageMigratorV0V1 migrate];
    [self postMigrateCheck];
}

- (void)postMigrateCheck {
    NSDictionary *dirs = [self getDirs];
    NSDictionary *files = [self getFiles];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    for(NSString *path in files) {
        if([fm fileExistsAtPath:path isDirectory:&isDir]) {
            XCTFail(@"Expected path to not exist: %@", path);
        }
    }
    for(NSString *path in dirs) {
        if([fm fileExistsAtPath:path isDirectory:&isDir]) {
            XCTFail(@"Expected path to not exist: %@", path);
        }
    }

    NSString *cachesDir = [self getCachesDir];
    for(NSString *path in @[
        [cachesDir stringByAppendingPathComponent:@"bsg_kvstore"],
        [cachesDir stringByAppendingPathComponent:@"bugsnag"],
        [cachesDir stringByAppendingPathComponent:@"KSCrashReports"],
        [cachesDir stringByAppendingPathComponent:@"Sessions"],
                          ]) {
        if([fm fileExistsAtPath:path isDirectory:&isDir]) {
            XCTFail(@"Expected path to not exist: %@", path);
        }
    }

    for(NSString *path in files) {
        NSString *dstPath = files[path];
        if(![fm fileExistsAtPath:dstPath isDirectory:&isDir]) {
            XCTFail(@"Expected path to exist: %@", dstPath);
        }
        if(isDir) {
            XCTFail(@"Expected a file: %@", dstPath);
        }
    }
    for(NSString *path in dirs) {
        NSString *dstPath = dirs[path];
        if(![fm fileExistsAtPath:dstPath isDirectory:&isDir]) {
            XCTFail(@"Expected path to exist: %@", dstPath);
        }
        if(!isDir) {
            XCTFail(@"Expected a directory: %@", dstPath);
        }
    }

}

@end
