//
//  Tuner.m
//  Clay
//
//  Created by Lakr Aream on 2022/5/7.
//

#import "Tuner.h"

#import "UIMenuAlwaysBlur.h"

@implementation Tuner

+(void) initializeTuner
{
    [Tuner makeUIMenuAlwaysBlur];
}

+(void) tuneMessageWithClass:(Class) targetClass
                withSelector:(SEL) targetSelector
                 usingNewImp:(IMP) newImp
          settingReplacedImp:(IMP*) settingImp
{
    if (!targetClass || !targetSelector || !newImp || !settingImp) {
#ifdef DEBUG
        NSLog(@"calling Tuner with undefined value is not supported");        
#endif
        return;
    }
    Method currentMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (!currentMethod) {
#ifdef DEBUG
        NSLog(
            @"Tuner did not found corresponding method for %@ with selector %@",
            NSStringFromClass(targetClass),
            NSStringFromSelector(targetSelector)
        );
#endif
        return;
    }
    
    *settingImp = method_setImplementation(currentMethod, newImp);
    
#ifdef DEBUG
    NSLog(
        @"Tuner replacing imp for %@ by setting %p to %p",
        NSStringFromClass(targetClass),
        *settingImp,
        newImp
    );
#endif
}

@end
