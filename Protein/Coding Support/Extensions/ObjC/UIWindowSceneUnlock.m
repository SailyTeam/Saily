//
//  UIWindowSceneUnlock.m
//  Protein
//
//  Created by Lakr Aream on 2020/5/10.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#include "UIWindowSceneUnlock.h"

void unlockUISceneSizeRestrictions(UIWindowScene* target) {

#define LIMIT_WIDTH 50
#define LIMIT_HEIGHT 50

    
    CGSize size = CGSizeMake(LIMIT_WIDTH, LIMIT_HEIGHT);
    
    id app = NSClassFromString(@"NSApplication");
    id shared = [app valueForKeyPath:@"sharedApplication"];
    id mainWindow = [shared valueForKeyPath:@"mainWindow"];
    
    NSValue *nssize = [NSValue valueWithCGSize:size];
    [mainWindow setValue:nssize forKeyPath:@"minSize"];
    
    UISceneSizeRestrictions* overrideTarget = [UISceneSizeRestrictions alloc];
    overrideTarget.minimumSize = CGSizeMake(LIMIT_WIDTH, LIMIT_HEIGHT);
    overrideTarget.maximumSize = CGSizeMake(23333, 23333);
    [target setValue:overrideTarget forKey:@"_sizeRestrictions"];
    NSLog(@"UISceneSizeRestrictions unlocked");
    
}
