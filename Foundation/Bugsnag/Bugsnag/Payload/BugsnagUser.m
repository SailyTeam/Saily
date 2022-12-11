//
//  BugsnagUser.m
//  Bugsnag
//
//  Created by Jamie Lynch on 24/11/2017.
//  Copyright © 2017 Bugsnag. All rights reserved.
//

#import "BugsnagUser+Private.h"

#import "BSG_KSSystemInfo.h"

BSG_OBJC_DIRECT_MEMBERS
@implementation BugsnagUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if ((self = [super init])) {
        _id = dict[@"id"];
        _email = dict[@"email"];
        _name = dict[@"name"];
    }
    return self;
}

- (instancetype)initWithId:(NSString *)id name:(NSString *)name emailAddress:(NSString *)emailAddress {
    if ((self = [super init])) {
        _id = id;
        _name = name;
        _email = emailAddress;
    }
    return self;
}

- (NSDictionary *)toJson {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"id"] = self.id;
    dict[@"email"] = self.email;
    dict[@"name"] = self.name;
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (BugsnagUser *)withId {
    if (self.id) {
        return self;
    } else {
        return [[BugsnagUser alloc] initWithId:[BSG_KSSystemInfo deviceAndAppHash]
                                          name:self.name
                                  emailAddress:self.email];
    }
}

@end

// MARK: - User Persistence

static NSString * const BugsnagUserEmailAddressKey = @"BugsnagUserEmailAddress";
static NSString * const BugsnagUserIdKey           = @"BugsnagUserUserId";
static NSString * const BugsnagUserNameKey         = @"BugsnagUserName";

BugsnagUser * BSGGetPersistedUser(void) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[BugsnagUser alloc] initWithId:[userDefaults stringForKey:BugsnagUserIdKey]
                                      name:[userDefaults stringForKey:BugsnagUserNameKey]
                              emailAddress:[userDefaults stringForKey:BugsnagUserEmailAddressKey]];
}

void BSGSetPersistedUser(BugsnagUser *user) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:user.email forKey:BugsnagUserEmailAddressKey];
    [userDefaults setObject:user.id forKey:BugsnagUserIdKey];
    [userDefaults setObject:user.name forKey:BugsnagUserNameKey];
}
