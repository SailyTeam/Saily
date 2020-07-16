//
//  dpkgInline.h
//  Sail
//
//  Created by Lakr Aream on 2020/2/22.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#ifndef dpkgInline_h
#define dpkgInline_h

#include <stdio.h>

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>

#define DPKG_VERSION_OBJECT(e, v, r) \
    (struct dpkg_version){ .epoch = (e), .version = (v), .revision = (r) }

/**
 * Data structure representing a Debian version.
 *
 * @see deb-version(5)
 */
struct dpkg_version {
    /** The epoch. It will be zero if no epoch is present. */
    unsigned int epoch;
    /** The upstream part of the version. */
    const char *version;
    /** The Debian revision part of the version. */
    const char *revision;
};

int parseversion(struct dpkg_version *rversion, const char *string);
int dpkg_version_compare(const struct dpkg_version *a, const struct dpkg_version *b);

#endif /* dpkgInline_h */
