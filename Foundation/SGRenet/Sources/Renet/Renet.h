//
//  SGRenet.h
//  RootUtilHelper
//
//  Created by soulghost on 2020/5/26.
//  Copyright © 2020 soulghost. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGRenet : NSObject

+ (int)resolveNetworkProblemForAppWithBundleId:(NSString *)bundleId;

@end

NS_ASSUME_NONNULL_END
