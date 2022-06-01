//
//  Constructor.m
//  
//
//  Created by Lakr Aream on 2022/6/1.
//

#import <Foundation/Foundation.h>

#import "Tuner.h"

__attribute__((constructor)) void tunner_constructor(void) {
    [Tuner initializeTuner];
}
