//
// Created by Jamie Lynch on 04/12/2017.
// Copyright (c) 2017 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * BugsnagHTTPHeaderName NS_TYPED_ENUM;

static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNameApiKey             = @"Bugsnag-Api-Key";
static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNameIntegrity          = @"Bugsnag-Integrity";
static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNamePayloadVersion     = @"Bugsnag-Payload-Version";
static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNameSentAt             = @"Bugsnag-Sent-At";
static BugsnagHTTPHeaderName const BugsnagHTTPHeaderNameStacktraceTypes    = @"Bugsnag-Stacktrace-Types";

typedef NS_ENUM(NSInteger, BSGDeliveryStatus) {
    /// The payload was delivered successfully and can be deleted.
    BSGDeliveryStatusDelivered,
    /// The payload was not delivered but can be retried, e.g. when there was a loss of connectivity.
    BSGDeliveryStatusFailed,
    /// The payload cannot be delivered and should be deleted without attempting to retry.
    BSGDeliveryStatusUndeliverable,
};

void BSGPostJSONData(NSURLSession *URLSession,
                     NSData *data,
                     NSDictionary<BugsnagHTTPHeaderName, NSString *> *headers,
                     NSURL *url,
                     void (^ completionHandler)(BSGDeliveryStatus status, NSError *_Nullable error));

NSString *_Nullable BSGIntegrityHeaderValue(NSData *_Nullable data);

NS_ASSUME_NONNULL_END
