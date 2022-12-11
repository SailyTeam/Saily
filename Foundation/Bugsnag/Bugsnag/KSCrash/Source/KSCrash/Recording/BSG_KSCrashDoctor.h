//
//  BSG_KSCrashDoctor.h
//  BSG_KSCrash
//
//  Created by Karl Stenerud on 2012-11-10.
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BSGDefines.h"

BSG_OBJC_DIRECT_MEMBERS
@interface BSG_KSCrashDoctor : NSObject

- (NSString *)diagnoseCrash:(NSDictionary *)crashReport;

@end
