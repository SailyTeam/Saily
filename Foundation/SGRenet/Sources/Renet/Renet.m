//
//  SGRenet.m
//  RootUtilHelper
//
//  Created by soulghost on 2020/5/26.
//  Copyright © 2020 soulghost. All rights reserved.
//

#import "Renet.h"

#define c(clazz) ((id)(NSClassFromString(@#clazz)))

@implementation SGRenet

+ (int)resolveNetworkProblemForAppWithBundleId:(NSString *)bundleId {
    @try {
        [SGRenet kResolveNetworkProblemForAppWithBundleId: bundleId];
    } @catch (NSException *exception) {
        NSLog(@"[*] Exception Catches %@", exception.description);
    } @finally { }
}

+ (int)kResolveNetworkProblemForAppWithBundleId:(NSString *)bundleId {
	NSBundle *cellularBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SettingsCellular.framework"];
	if (![cellularBundle load]) {
		cellularBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Preferences.framework"];
		if ([cellularBundle load]) {
			NSLog(@"[+] Preferences.framework is loaded\n");
		} else {
			NSLog(@"[-] error: cannot load Preferences.framework\n");
			return EPERM;
		}
	} else {
		NSLog(@"[+] SettingsCellular.framework is loaded\n");
	}

	NSLog(@"[*] fixup network problem for %s\n", bundleId.UTF8String);
	if (c(AppWirelessDataUsageManager)) {
		[c(AppWirelessDataUsageManager) setAppWirelessDataOption:[NSNumber numberWithInteger:3]
		 forBundleIdentifier:bundleId
		 completionHandler:nil];
		[c(AppWirelessDataUsageManager) setAppCellularDataEnabled:[NSNumber numberWithInt:1]
		 forBundleIdentifier:bundleId
		 completionHandler:nil];
		NSLog(@"[+] setup AppWirelessDataUsageManager\n");
        return 0;
	} else if (c(PSAppDataUsagePolicyCache)) {
		[[c(PSAppDataUsagePolicyCache) sharedInstance] setUsagePoliciesForBundle:bundleId
		 cellular:YES
		 wifi:YES];
		NSLog(@"[+] setup PSAppDataUsagePolicyCache\n");
        return 0;
	} else {
		NSLog(@"[-] error: cannot realize AppWirelessDataUsageManager or PSAppDataUsagePolicyCache\n");
	}
    return EPERM;
}

- (void)setAppWirelessDataOption:(NSNumber *)options forBundleIdentifier:(NSString *)bundleId completionHandler:(id)completionHandler {
	assert(false);
}

- (void)setAppCellularDataEnabled:(NSNumber *)enabled forBundleIdentifier:(NSString *)bundleId completionHandler:(id)completionHandler {
	assert(false);
}

- (void)setUsagePoliciesForBundle:(NSString *)bundleId cellular:(BOOL)cellular wifi:(BOOL)wifi {
	assert(false);
}

+ (instancetype)sharedInstance {
	assert(false);
	return nil;
}

@end
