//
//  BSGDefines.h
//  Bugsnag
//
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#ifndef BSGDefines_h
#define BSGDefines_h

#include <TargetConditionals.h>

// Capabilities dependent upon system defines and files
#define BSG_HAVE_BATTERY                      (                 TARGET_OS_IOS                 || TARGET_OS_WATCH)
#define BSG_HAVE_MACH_EXCEPTIONS              (TARGET_OS_OSX || TARGET_OS_IOS                                   )
#define BSG_HAVE_MACH_THREADS                 (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV                   )
#define BSG_HAVE_OOM_DETECTION                (                 TARGET_OS_IOS || TARGET_OS_TV                   ) && !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST
#define BSG_HAVE_REACHABILITY                 (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV                   )
#define BSG_HAVE_REACHABILITY_WWAN            (                 TARGET_OS_IOS || TARGET_OS_TV                   )
#define BSG_HAVE_SIGNAL                       (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV                   )
#define BSG_HAVE_SIGALTSTACK                  (TARGET_OS_OSX || TARGET_OS_IOS                                   )
#define BSG_HAVE_SYSCALL                      (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV                   )
#define BSG_HAVE_UIDEVICE                     __has_include(<UIKit/UIDevice.h>)
#define BSG_HAVE_WINDOW                       (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV                   )

// Capabilities dependent upon previously defined capabilities
#define BSG_HAVE_APP_HANG_DETECTION           (BSG_HAVE_MACH_THREADS)

#ifdef __OBJC__

// Constructs a key path, with a compile-time check in DEBUG builds.
// https://pspdfkit.com/blog/2017/even-swiftier-objective-c/#checked-keypaths
#if defined(DEBUG) && DEBUG
#define BSG_KEYPATH(object, property) ((void)(NO && ((void)object.property, NO)), @ #property)
#else
#define BSG_KEYPATH(object, property) @ #property
#endif

// Causes methods to have no associated Objective-C metadata and use C function calling convention.
// See https://reviews.llvm.org/D69991
// Overridden when building for unit testing to make private interfaces accessible. 
#ifndef BSG_OBJC_DIRECT_MEMBERS
#if __has_attribute(objc_direct_members) && (__clang_major__ > 11)
#define BSG_OBJC_DIRECT_MEMBERS __attribute__((objc_direct_members))
#else
#define BSG_OBJC_DIRECT_MEMBERS
#endif
#endif

#endif /* __OBJC__ */

// Reference: http://iphonedevwiki.net/index.php/CoreFoundation.framework
#define kCFCoreFoundationVersionNumber_iOS_12_0 1556.00

#endif /* BSGDefines_h */
