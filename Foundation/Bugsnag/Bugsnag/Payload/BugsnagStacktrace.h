//
//  BugsnagStacktrace.h
//  Bugsnag
//
//  Created by Jamie Lynch on 06/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BSGDefines.h"

@class BugsnagStackframe;

/**
 * Representation of a stacktrace in a bugsnag error report
 */
BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagStacktrace : NSObject

- (instancetype)initWithTrace:(NSArray<NSDictionary *> *)trace
                 binaryImages:(NSArray<NSDictionary *> *)binaryImages;

+ (instancetype)stacktraceFromJson:(NSArray<NSDictionary *> *)json;

@property (nonatomic) NSMutableArray<BugsnagStackframe *> *trace;

@end
