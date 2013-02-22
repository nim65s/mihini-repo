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
/*
 * awt_std.h
 *
 * Created on: Jan 05, 2009
 * Author: Eric Klumpp & Cuero Bugot & Laurent Barthelemy
 */

/**
 * @file awt_std.h
 * @brief Standard libraries adaptation for  hardware abstraction.
 *
 * This header gives a abstraction to allows to use various C standard libraries functions on all hardware devices.
 * @ingroup common
 */


#ifndef AWTDA_PORT_H_
#define AWTDA_PORT_H_


#ifdef __OAT_API_VERSION__

#define SYSTEM_OAT

#include "adl_global.h"
#include "swi_log.h"

#define STDERR 1
#define STDOUT 1

// Global macros
#define ASSERT(a)
#define MIN(a, b)    (a < b ? a : b)
#define assert(a)
//if(!a){SWI_TRACE(STDERR,#a##"-Assert was not satisfied at "__FILE__":"__LINE__);}


#define fatal_error(...) SWI_LOG("AWT-STD", ERROR, __VA_ARGS__)
#define log_error(a)

// standard functions symbols to be overwritten by custom implementation
void* malloc( size_t size );
void free( void *ptr );
int printf(const char * fmt, ...);

static inline void * lib_realloc ( void * src, size_t srcSize, size_t newSize)
{
    void* res;
    res = adl_memGet( newSize );
    if ( newSize > srcSize )
        wm_memset( res + srcSize, 0, newSize - srcSize );
    if ( src != NULL ) {
        wm_memcpy( res, src, MIN(srcSize, newSize) );
        adl_memRelease( src );
    }
    return res;
}

#else    // __OAT_API_VERSION__

#define SYSTEM_LINUX

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "swi_log.h"
#ifdef WITH_TOSTRING
  #include <stdio.h>
#endif // WITH_TOSTRING


// Global macros
#ifndef NDEBUG
  #define ASSERT assert
#else //NDEBUG
  #define ASSERT(a)
#endif //NDEBUG

// Memory allocation functions

//#define realloc lib_realloc
static inline void * lib_realloc ( void * ptr, size_t prevSize, size_t size )
{
  ASSERT(size);
  return realloc(ptr, size);
}

#define fatal_error(...)            \
  SWI_LOG("AWT-STD", ERROR, __VA_ARGS__);    \
  assert(0)

#endif    // __OAT_API_VERSION__

#endif    // AWTDA_PORT_H_
