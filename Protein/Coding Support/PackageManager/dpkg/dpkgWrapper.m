//
//  dpkgWrapper.m
//  Sail
//
//  Created by Lakr Aream on 2020/2/22.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import "dpkgWrapper.h"
#import "dpkgInline.h"

@implementation dpkgWrapper

-(BOOL)isVersionVaild:(NSString *)a {
    struct dpkg_version v;
    return (parseversion(&v, (const char*)[a UTF8String]) == 0);
}

-(int)compareVersionA:(NSString *)a andB:(NSString *)b {
    struct dpkg_version da, db;
    int ra = parseversion(&da, (const char*)[a UTF8String]);
    int rb = parseversion(&db, (const char*)[b UTF8String]);
    if (ra != 0 || rb != 0) {
        NSLog(@"[Error] compareVersionA&B contain invaild version string");
        return 0;
    }
    return dpkg_version_compare(&da, &db);
}

@end
