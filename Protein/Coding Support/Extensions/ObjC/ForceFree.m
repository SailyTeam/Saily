//
//  ForceFree.m
//  Protein
//
//  Created by Lakr Aream on 2020/5/11.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import <Foundation/Foundation.h>

#if DEBUG
void ForceFree(id target) {
    free((__bridge void *)target); // memory debug
}
#endif

