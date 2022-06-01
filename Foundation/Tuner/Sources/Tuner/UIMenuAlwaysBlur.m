//
//  UIMenuAlwaysBlur.m
//  Clay
//
//  Created by Lakr Aream on 2022/5/7.
//

#import "UIMenuAlwaysBlur.h"

// -[_UIContextMenuPresentationController backgroundEffectView]

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

static void (*original__UIContextMenuPresentationAnimation__setBackgroundVisible)(id self, SEL _cmd, BOOL visible);
static void replaced__UIContextMenuPresentationAnimation__setBackgroundVisible(id self, SEL _cmd, BOOL visible)
{
    if (original__UIContextMenuPresentationAnimation__setBackgroundVisible) {
        original__UIContextMenuPresentationAnimation__setBackgroundVisible(self, _cmd, visible);
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            // Some tricky hack to make background have a blur effect.
            UIVisualEffectView *visualEffectView = [self valueForKey:@"_backgroundView"];
            if (visible) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
                id zoomEffect = [NSClassFromString(@"_UIZoomEffect") performSelector:@selector(zoomEffectWithMagnitude:)
                                                                          withObject:@(0.024)];
                [visualEffectView performSelector:@selector(setBackgroundEffects:)
                                       withObject:@[blurEffect, zoomEffect]];
            }
        }
    }
};

@implementation Tuner (UIMenuAlwaysBlur)

+(void) makeUIMenuAlwaysBlur
{
    [Tuner tuneMessageWithClass:NSClassFromString(@"_UIContextMenuPresentationAnimation")
                   withSelector:NSSelectorFromString(@"_setBackgroundVisible:")
                    usingNewImp:(IMP)&replaced__UIContextMenuPresentationAnimation__setBackgroundVisible
             settingReplacedImp:(IMP *)&original__UIContextMenuPresentationAnimation__setBackgroundVisible];
}

@end

#pragma clang diagnostic pop
