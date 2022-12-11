//
//  BSG_KSCrashDoctor.m
//  BSG_KSCrash
//
//  Created by Karl Stenerud on 2012-11-10.
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//

#import "BSG_KSCrashDoctor.h"

#import "BSG_KSCrashReportFields.h"
#import "BSG_KSSystemInfo.h"
#import "BugsnagLogger.h"

BSG_OBJC_DIRECT_MEMBERS
@implementation BSG_KSCrashDoctor

- (NSDictionary *)crashReport:(NSDictionary *)report {
    return report[@BSG_KSCrashField_Crash];
}

- (NSDictionary *)infoReport:(NSDictionary *)report {
    return report[@BSG_KSCrashField_Report];
}

- (NSDictionary *)errorReport:(NSDictionary *)report {
    return [self crashReport:report][@BSG_KSCrashField_Error];
}

- (NSString *)mainExecutableNameForReport:(NSDictionary *)report {
    NSDictionary *info = [self infoReport:report];
    return info[@BSG_KSCrashField_ProcessName];
}

- (NSDictionary *)crashedThreadReport:(NSDictionary *)report {
    NSDictionary *crashReport = [self crashReport:report];
    NSDictionary *crashedThread =
            crashReport[@BSG_KSCrashField_CrashedThread];
    if (crashedThread != nil) {
        return crashedThread;
    }

    for (NSDictionary *thread in
            crashReport[@BSG_KSCrashField_Threads]) {
        if ([thread[@BSG_KSCrashField_Crashed] boolValue]) {
            return thread;
        }
    }
    return nil;
}

- (NSArray *)backtraceFromThreadReport:(NSDictionary *)threadReport {
    NSDictionary *backtrace =
            threadReport[@BSG_KSCrashField_Backtrace];
    return backtrace[@BSG_KSCrashField_Contents];
}

- (NSDictionary *)lastInAppStackEntry:(NSDictionary *)report {
    NSString *executableName = [self mainExecutableNameForReport:report];
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    NSArray *backtrace = [self backtraceFromThreadReport:crashedThread];
    for (NSDictionary *entry in backtrace) {
        NSString *objectName =
                entry[@BSG_KSCrashField_ObjectName];
        if ([objectName isEqualToString:executableName]) {
            return entry;
        }
    }
    return nil;
}

- (BOOL)isInvalidAddress:(NSDictionary *)errorReport {
    NSDictionary *machError = errorReport[@BSG_KSCrashField_Mach];
    if (machError != nil) {
        NSString *exceptionName =
                machError[@BSG_KSCrashField_ExceptionName];
        return [exceptionName isEqualToString:@"EXC_BAD_ACCESS"];
    }
    NSDictionary *signal = errorReport[@BSG_KSCrashField_Signal];
    NSString *sigName = signal[@BSG_KSCrashField_Name];
    return [sigName isEqualToString:@"SIGSEGV"];
}

- (BOOL)isMathError:(NSDictionary *)errorReport {
    NSDictionary *machError = errorReport[@BSG_KSCrashField_Mach];
    if (machError != nil) {
        NSString *exceptionName =
                machError[@BSG_KSCrashField_ExceptionName];
        return [exceptionName isEqualToString:@"EXC_ARITHMETIC"];
    }
    NSDictionary *signal = errorReport[@BSG_KSCrashField_Signal];
    NSString *sigName = signal[@BSG_KSCrashField_Name];
    return [sigName isEqualToString:@"SIGFPE"];
}

- (BOOL)isMemoryCorruption:(NSDictionary *)report {
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    NSArray *backtrace = [self backtraceFromThreadReport:crashedThread];
    for (NSDictionary *entry in backtrace) {
        NSString *objectName =
                entry[@BSG_KSCrashField_ObjectName];
        NSString *symbolName =
                entry[@BSG_KSCrashField_SymbolName];
        if ([symbolName isEqualToString:@"objc_autoreleasePoolPush"]) {
            return YES;
        }
        if ([symbolName isEqualToString:@"free_list_checksum_botch"]) {
            return YES;
        }
        if ([symbolName isEqualToString:@"szone_malloc_should_clear"]) {
            return YES;
        }
        if ([symbolName isEqualToString:@"lookUpMethod"] &&
            [objectName isEqualToString:@"libobjc.A.dylib"]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)isStackOverflow:(NSDictionary *)crashedThreadReport {
    NSDictionary *stack =
            crashedThreadReport[@BSG_KSCrashField_Stack];
    return [stack[@BSG_KSCrashField_Overflow] boolValue];
}

- (NSString *)diagnoseCrash:(NSDictionary *)report {
    @try {
        NSString *lastFunctionName = [self lastInAppStackEntry:report][@BSG_KSCrashField_SymbolName];
        NSDictionary *crashedThreadReport = [self crashedThreadReport:report];
        NSDictionary *errorReport = [self errorReport:report];

        if ([self isStackOverflow:crashedThreadReport]) {
            return [NSString
                stringWithFormat:@"Stack overflow in %@", lastFunctionName];
        }

        if ([self isMemoryCorruption:report]) {
            return @"Rogue memory write has corrupted memory.";
        }

        if ([self isMathError:errorReport]) {
            return @"Math error (usually caused from division by 0).";
        }

        if ([self isInvalidAddress:errorReport]) {
            uintptr_t address = (uintptr_t)[errorReport[@BSG_KSCrashField_Address] unsignedLongLongValue];
            if (address == 0) {
                return @"Attempted to dereference null pointer.";
            }
            return [NSString stringWithFormat:
                    @"Attempted to dereference garbage pointer %p.",
                    (void *)address];
        }

        return nil;
    } @catch (NSException *e) {
        bsg_log_debug(@"%@", e);
        return nil;
    }
}

@end
