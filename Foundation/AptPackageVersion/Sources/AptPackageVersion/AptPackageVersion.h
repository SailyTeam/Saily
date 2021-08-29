//
//  dpkgWrapper.h
//  Sail
//
//  Created by Lakr Aream on 2020/2/22.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AptPackageVersion : NSObject

+ (BOOL)isVersionVaild:(NSString *)a;

/// returns compare result
/// @param a version String A
/// @param b version String B
/// @retval 0 If a and b are equal.
/// @retval <0 If a is smaller than b.
/// @retval >0 If a is greater than b.
+ (int)compareVersionA:(NSString *)a andB:(NSString *)b;

@end

NS_ASSUME_NONNULL_END
