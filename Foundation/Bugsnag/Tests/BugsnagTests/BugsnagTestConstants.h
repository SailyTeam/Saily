//
//  BugsnagTestConstants.h
//  Bugsnag
//
//  Created by Robin Macharg on 22/01/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#ifndef BugsnagTestConstants_h
#define BugsnagTestConstants_h

/**
 * Dummy apiKey values of various lengths
 */

//                                                         0         1         2         3         4        5
// One string to rule(r) them all:                         12345678901234567890123456789012345678901234567890
static NSString * _Nonnull const DUMMY_APIKEY_32CHAR_1 = @"0192837465afbecd0192837465afbecd"; // the correct length
static NSString * _Nonnull const DUMMY_APIKEY_32CHAR_2 = @"aabbccddeeff00112233445566778899";
static NSString * _Nonnull const DUMMY_APIKEY_32CHAR_3 = @"99887766554433221100ffeeddccbbaa";
static NSString * _Nonnull const DUMMY_APIKEY_32CHAR_4 = @"98765432109876543210abcdefabcdef";
static NSString * _Nonnull const DUMMY_APIKEY_16CHAR   = @"0192837465afbecd"; // too short
static NSString * _Nonnull const DUMMY_APIKEY_48CHAR   = @"0192837465afbecd0192837465afbecd0192837465afbecd"; // too long

#endif /* BugsnagTestConstants_h */
