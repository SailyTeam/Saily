#import <XCTest/XCTest.h>

#import "BSGConnectivity.h"
#import "BSGDefines.h"

@interface BSGConnectivityTest : XCTestCase
@end

@implementation BSGConnectivityTest

- (void)tearDown {
    // Reset connectivity state cache
    BSGConnectivityShouldReportChange(0);
    [BSGConnectivity stopMonitoring];
}

- (void)testConnectivityRepresentations {
    XCTAssertEqualObjects(@"none", BSGConnectivityFlagRepresentation(0));
    XCTAssertEqualObjects(@"none", BSGConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsIsDirect));
    #if BSG_HAVE_REACHABILITY_WWAN
        // kSCNetworkReachabilityFlagsIsWWAN does not exist on macOS
        XCTAssertEqualObjects(@"none", BSGConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsIsWWAN));
        XCTAssertEqualObjects(@"cellular", BSGConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsIsWWAN | kSCNetworkReachabilityFlagsReachable));
    #endif
    XCTAssertEqualObjects(@"wifi", BSGConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsReachable));
    XCTAssertEqualObjects(@"wifi", BSGConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsDirect));
}

- (void)testValidHost {
    XCTAssertTrue([BSGConnectivity isValidHostname:@"example.com"]);
    // Could be an internal network hostname
    XCTAssertTrue([BSGConnectivity isValidHostname:@"foo"]);

    // Definitely will not work as expected
    XCTAssertFalse([BSGConnectivity isValidHostname:@""]);
    XCTAssertFalse([BSGConnectivity isValidHostname:nil]);
    XCTAssertFalse([BSGConnectivity isValidHostname:@"localhost"]);
    XCTAssertFalse([BSGConnectivity isValidHostname:@"127.0.0.1"]);
    XCTAssertFalse([BSGConnectivity isValidHostname:@"::1"]);
}

- (void)mockMonitorURLWithCallback:(BSGConnectivityChangeBlock)block {
    [BSGConnectivity monitorURL:[NSURL URLWithString:@""]
                  usingCallback:block];
}

@end
