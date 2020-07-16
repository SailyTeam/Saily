//
//  dpkgInline.c
//  Sail
//
//  Created by Lakr Aream on 2020/2/22.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#include "dpkgInline.h"

int dpkg_put_error(const char* err_str) {
    printf("[dpkg Inline] |E| %s\n", err_str);
    return -1;
}

int dpkg_put_warn(const char* err_str) {
    printf("[dpkg Inline] |W| %s\n", err_str);
    return 0;
}

/**
 * Parse a version string and check for invalid syntax.
 *
 * Distinguish between lax (warnings) and strict (error) parsing.
 *
 * @param rversion The parsed version.
 * @param string The version string to parse.
 *
 * @retval  0 On success.
 * @retval -1 On failure, and err is set accordingly.
 */
int parseversion(struct dpkg_version *rversion, const char *string) {
  char *hyphen, *colon, *eepochcolon;
  const char *end, *ptr;

  /* Trim leading and trailing space. */
  while (*string && isblank(*string))
    string++;

  if (!*string)
    return dpkg_put_error("version string is empty");

  /* String now points to the first non-whitespace char. */
  end = string;
  /* Find either the end of the string, or a whitespace char. */
  while (*end && !isblank(*end))
    end++;
  /* Check for extra chars after trailing space. */
  ptr = end;
  while (*ptr && isblank(*ptr))
    ptr++;
  if (*ptr)
    return dpkg_put_error("version string has embedded spaces");

  colon= strchr(string,':');
  if (colon) {
    long epoch;

    errno = 0;
    epoch = strtol(string, &eepochcolon, 10);
    if (string == eepochcolon)
      return dpkg_put_error("epoch in version is empty");
    if (colon != eepochcolon)
      return dpkg_put_error("epoch in version is not number");
    if (epoch < 0)
      return dpkg_put_error("epoch in version is negative");
    if (epoch > INT_MAX || errno == ERANGE)
      return dpkg_put_error("epoch in version is too big");
    if (!*++colon)
      return dpkg_put_error("nothing after colon in version number");
    string= colon;
    rversion->epoch= (unsigned int)epoch;
  } else {
    rversion->epoch= 0;
  }
  rversion->version= strndup(string,end-string); // nfstrnsave
  hyphen= strrchr(rversion->version,'-');
  if (hyphen) {
    *hyphen++ = '\0';

    if (*hyphen == '\0')
      return dpkg_put_error("revision number is empty");
  }
  rversion->revision= hyphen ? hyphen : "";

  /* XXX: Would be faster to use something like cisversion and cisrevision. */
  ptr = rversion->version;
  if (!*ptr)
    return dpkg_put_error("version number is empty");
  if (*ptr && !isdigit(*ptr++))
    return dpkg_put_error("version number does not start with digit");
  for (; *ptr; ptr++) {
    if (!isdigit(*ptr) && !isalpha(*ptr) && strchr(".-+~:", *ptr) == NULL)
      return dpkg_put_error("invalid character in version number");
  }
  for (ptr = rversion->revision; *ptr; ptr++) {
    if (!isdigit(*ptr) && !isalpha(*ptr) && strchr(".+~", *ptr) == NULL)
      return dpkg_put_error("invalid character in revision number");
  }

  return 0;
}

/**
 * Give a weight to the character to order in the version comparison.
 *
 * @param c An ASCII character.
 */
static int
order(int c)
{
    if (isdigit(c))
        return 0;
    else if (isalpha(c))
        return c;
    else if (c == '~')
        return -1;
    else if (c)
        return c + 256;
    else
        return 0;
}

static int
verrevcmp(const char *a, const char *b)
{
    if (a == NULL)
        a = "";
    if (b == NULL)
        b = "";

    while (*a || *b) {
        int first_diff = 0;

        while ((*a && !isdigit(*a)) || (*b && !isdigit(*b))) {
            int ac = order(*a);
            int bc = order(*b);

            if (ac != bc)
                return ac - bc;

            a++;
            b++;
        }
        while (*a == '0')
            a++;
        while (*b == '0')
            b++;
        while (isdigit(*a) && isdigit(*b)) {
            if (!first_diff)
                first_diff = *a - *b;
            a++;
            b++;
        }

        if (isdigit(*a))
            return 1;
        if (isdigit(*b))
            return -1;
        if (first_diff)
            return first_diff;
    }

    return 0;
}

/**
 * Compares two Debian versions.
 *
 * This function follows the convention of the comparator functions used by
 * qsort().
 *
 * @see deb-version(5)
 *
 * @param a The first version.
 * @param b The second version.
 *
 * @retval 0 If a and b are equal.
 * @retval <0 If a is smaller than b.
 * @retval >0 If a is greater than b.
 */
int
dpkg_version_compare(const struct dpkg_version *a,
                     const struct dpkg_version *b)
{
    int rc;

    if (a->epoch > b->epoch)
        return 1;
    if (a->epoch < b->epoch)
        return -1;

    rc = verrevcmp(a->version, b->version);
    if (rc)
        return rc;

    return verrevcmp(a->revision, b->revision);
}
