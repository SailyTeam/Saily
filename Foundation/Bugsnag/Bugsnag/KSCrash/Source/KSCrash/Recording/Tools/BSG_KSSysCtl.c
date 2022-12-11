//
//  KSSysCtl.m
//
//  Created by Karl Stenerud on 2012-02-19.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include "BSG_KSSysCtl.h"

//#define BSG_KSLogger_LocalLevel TRACE
#include "BSG_KSLogger.h"

#include <errno.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <stdlib.h>
#include <string.h>

#define CHECK_SYSCTL_NAME(TYPE, CALL)                                          \
    if (0 != (CALL)) {                                                         \
        BSG_KSLOG_ERROR("Could not get %s value for %s: %s", #CALL, name,      \
                        strerror(errno));                                      \
        return 0;                                                              \
    }

int32_t bsg_kssysctl_int32ForName(const char *const name) {
    int32_t value = 0;
    size_t size = sizeof(value);

    CHECK_SYSCTL_NAME(int32, sysctlbyname(name, &value, &size, NULL, 0));

    return value;
}

size_t bsg_kssysctl_stringForName(const char *const name, char *const value,
                                  const size_t maxSize) {
    size_t size = value == NULL ? 0 : maxSize;

    CHECK_SYSCTL_NAME(string, sysctlbyname(name, value, &size, NULL, 0));

    return size;
}

bool bsg_kssysctl_getMacAddress(const char *const name,
                                char *const macAddressBuffer) {
    // Based off
    // http://iphonedevelopertips.com/device/determine-mac-address.html

    int mib[6] = {CTL_NET, AF_ROUTE,      0,
                  AF_LINK, NET_RT_IFLIST, (int)if_nametoindex(name)};
    if (mib[5] == 0) {
        BSG_KSLOG_ERROR("Could not get interface index for %s: %s", name,
                        strerror(errno));
        return false;
    }

    size_t length;
    if (sysctl(mib, 6, NULL, &length, NULL, 0) != 0) {
        BSG_KSLOG_ERROR("Could not get interface data for %s: %s", name,
                        strerror(errno));
        return false;
    }

    void *ifBuffer = malloc(length);
    if (ifBuffer == NULL) {
        BSG_KSLOG_ERROR("Out of memory");
        return false;
    }

    if (sysctl(mib, 6, ifBuffer, &length, NULL, 0) != 0) {
        BSG_KSLOG_ERROR("Could not get interface data for %s: %s", name,
                        strerror(errno));
        free(ifBuffer);
        return false;
    }

    struct if_msghdr *msgHdr = (struct if_msghdr *)ifBuffer;
    struct sockaddr_dl *sockaddr = (struct sockaddr_dl *)&msgHdr[1];
    memcpy(macAddressBuffer, LLADDR(sockaddr), 6);

    free(ifBuffer);

    return true;
}
