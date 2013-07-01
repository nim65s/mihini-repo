 /*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Sierra Wireless - initial API and implementation
 *******************************************************************************/

#include "returncodes.h"
#include <string.h> // strcmp(),
#include <stdlib.h> // bsearch()


// Array containing  returncodes as string value so that returncode[code] = name
static const char *const returncode[] =
{
  "OK",                   //   0
  "NOT_FOUND",            //  -1
  "OUT_OF_RANGE",         //  -2
  "NO_MEMORY",            //  -3
  "NOT_PERMITTED",        //  -4
  "UNSPECIFIED_ERROR",    //  -5
  "COMMUNICATION_ERROR",  //  -6
  "TIMEOUT",              //  -7
  "OVERFLOW",             //  -8
  "UNDERFLOW",            //  -9
  "WOULD_BLOCK",          // -10
  "DEADLOCK",             // -11
  "BAD_FORMAT",           // -12
  "DUPLICATE",            // -13
  "BAD_PARAMETER",        // -14
  "CLOSED",               // -15
  "IO_ERROR",             // -16
  "NOT_IMPLEMENTED",      // -17
  "BUSY",                 // -18
  "NOT_INITIALIZED",      // -19
  "END",                  // -20
  "NOT_AVAILABLE",        // -21
};


// Array containing returncode string and code value associated in a struct and sorted in string ascending order !
static const struct cn
{
    const rc_ReturnCode_t n;
    const char *name;
} const rc_names[] =
{
  {  -12, "BAD_FORMAT" },
  {  -14, "BAD_PARAMETER" },
  {  -18, "BUSY" },
  {  -15, "CLOSED" },
  {   -6, "COMMUNICATION_ERROR" },
  {  -11, "DEADLOCK" },
  {  -13, "DUPLICATE" },
  {  -20, "END" },
  {  -16, "IO_ERROR" },
  {  -21, "NOT_AVAILABLE" },
  {   -1, "NOT_FOUND" },
  {  -17, "NOT_IMPLEMENTED" },
  {  -19, "NOT_INITIALIZED" },
  {   -4, "NOT_PERMITTED" },
  {   -3, "NO_MEMORY" },
  {    0, "OK" },
  {   -2, "OUT_OF_RANGE" },
  {   -8, "OVERFLOW" },
  {   -7, "TIMEOUT" },
  {   -9, "UNDERFLOW" },
  {   -5, "UNSPECIFIED_ERROR" },
  {  -10, "WOULD_BLOCK" },
};



/* Converts a numeric status into a string, or returns NULL if not found. */
const char *rc_returncode2string( rc_ReturnCode_t n)
{
    n = -n;
    if (n >= 0 && n < sizeof(returncode)/sizeof(*returncode))
        return returncode[n];
    else
        return NULL;
}
static int compcn(const void *m1, const void *m2)
{
    struct cn *cn1 = (struct cn *) m1;
    struct cn *cn2 = (struct cn *) m2;
    return strcmp(cn1->name, cn2->name);
}


/* Converts a status string into a numeric code, or returns 1 if not found. */
rc_ReturnCode_t rc_string2returncode( const char *name)
{
    struct cn key, *res;
    key.name = name;
    if (!name) return 1;
    res = bsearch(&key, rc_names, (sizeof(rc_names)/sizeof(*rc_names)), sizeof(*rc_names), compcn);
    if (!res)
        return 1;
    else
        return res->n;
}


 
 