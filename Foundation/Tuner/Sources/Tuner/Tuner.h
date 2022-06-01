//
//  Tuner.h
//  Clay
//
//  Created by Lakr Aream on 2022/5/7.
//

#ifndef Tuner_h
#define Tuner_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tuner : NSObject

+(void) initializeTuner;
+(void) tuneMessageWithClass:(Class) targetClass
                withSelector:(SEL) targetSelector
                 usingNewImp:(IMP) newImp
          settingReplacedImp:(IMP _Nullable *_Nullable) settingImp;

NS_ASSUME_NONNULL_END

@end

#endif /* Tuner_h */
