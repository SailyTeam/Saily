//
//  Process.m
//  Protein
//
//  Created by Lakr Aream on 2020/7/14.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import "Process.h"

#include <stdio.h>
#include <dlfcn.h>

#import <spawn.h>

int _system(const char *) __DARWIN_ALIAS_C(system);

NSString* objcSpawnCommandSync(NSString* command) {
    
    NSString* realCommand = [@"/bin/bash -c \'" stringByAppendingFormat:@"%@\'", command];
    
    int status = _system([realCommand UTF8String]);
    
    return [[NSString alloc] initWithFormat:@"%d", status];
    
}
