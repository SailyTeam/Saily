//
//  ProteinKeyboardTrick.m
//  SIMDResearch
//
//  Created by soulghost on 2020/7/12.
//  Copyright © 2020 soulghost. All rights reserved.
//

#import "ProteinKeyboardTrick.h"
#import <objc/runtime.h>

static bool (*orig_boolForPreferenceKey)(__unsafe_unretained id self, SEL cmd, NSString *key) = NULL;

static bool hooked_boolForPreferenceKey(__unsafe_unretained id self, SEL cmd, NSString *key) {
    if ([key isEqualToString:@"UIKeyboardDidShowInternationalInfoIntroduction"]) {
        return YES;
    }
    return orig_boolForPreferenceKey(self, cmd, key);
}

@implementation ProteinKeyboardTrick

+ (void)load {
    if (access("/var/root/Library/Preferences/com.apple.Preferences.plist", F_OK) != 0) {
        symlink("/var/mobile/Library/Preferences/com.apple.Preferences.plist", "/var/root/Library/Preferences/com.apple.Preferences.plist");
    }
    
    Class clazz = objc_getClass("TIPreferencesController");
    if (!clazz) {
        NSLog(@"[KeyboardTrick] TIPreferencesController failed to load");
        return;
    }
    
    Method orig = class_getInstanceMethod(clazz, NSSelectorFromString(@"boolForPreferenceKey:"));
    if (!orig) {
        NSLog(@"[KeyboardTrick] TIPreferencesController boolForPreferenceKey failed to load");
        return;
    }
    
    orig_boolForPreferenceKey = (void *)method_getImplementation(orig);
    method_setImplementation(orig, (void *)&hooked_boolForPreferenceKey);
}

@end
