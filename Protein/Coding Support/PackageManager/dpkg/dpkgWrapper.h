//
//  dpkgWrapper.h
//  Sail
//
//  Created by Lakr Aream on 2020/2/22.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface dpkgWrapper : NSObject

-(BOOL)isVersionVaild:(NSString *)a;
-(int)compareVersionA:(NSString *)a andB:(NSString *)b;

@end

NS_ASSUME_NONNULL_END
