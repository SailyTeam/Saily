//
//  SGNetworkConfigurationModifier.m
//  RootUtilHelper
//
//  Created by soulghost on 2020/5/26.
//  Copyright © 2020 soulghost. All rights reserved.
//

#import "SGNetworkConfigurationModifier.h"

#define c(clazz) ((id)(NSClassFromString(@#clazz)))

@implementation SGNetworkConfigurationModifier

+ (void)resolveNetworkProblmeForAppWithBundleId:(NSString *)bundleId {
    NSBundle *cellularBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SettingsCellular.framework"];
    if (![cellularBundle load]) {
        cellularBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Preferences.framework"];
        if ([cellularBundle load]) {
            printf("[+] Preferences.framework is loaded\n");
        } else {
            printf("[-] error: cannot load Preferences.framework\n");
            return;
        }
    } else {
        printf("[+] SettingsCellular.framework is loaded\n");
    }
    
    printf("[*] fixup network problem for %s\n", bundleId.UTF8String);
    if (c(AppWirelessDataUsageManager)) {
        [c(AppWirelessDataUsageManager) setAppWirelessDataOption:[NSNumber numberWithInteger:3]
                                        forBundleIdentifier:bundleId
                                        completionHandler:nil];
        [c(AppWirelessDataUsageManager) setAppCellularDataEnabled:[NSNumber numberWithInt:1]
                                        forBundleIdentifier:bundleId
                                        completionHandler:nil];
        printf("[+] setup AppWirelessDataUsageManager\n");
    } else if (c(PSAppDataUsagePolicyCache)) {
        [[c(PSAppDataUsagePolicyCache) sharedInstance] setUsagePoliciesForBundle:bundleId
                                                       cellular:YES
                                                       wifi:YES];
        printf("[+] setup PSAppDataUsagePolicyCache\n");
    } else {
        printf("[-] error: cannot realize AppWirelessDataUsageManager or PSAppDataUsagePolicyCache\n");
    }
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
