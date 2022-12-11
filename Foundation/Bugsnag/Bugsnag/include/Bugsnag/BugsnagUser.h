//
//  BugsnagUser.h
//  Bugsnag
//
//  Created by Jamie Lynch on 24/11/2017.
//  Copyright © 2017 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Bugsnag/BugsnagDefines.h>

/**
 * Information about the current user of your application.
 */
BUGSNAG_EXTERN
@interface BugsnagUser : NSObject

@property (readonly, nullable, nonatomic) NSString *id;

@property (readonly, nullable, nonatomic) NSString *name;

@property (readonly, nullable, nonatomic) NSString *email;

@end
