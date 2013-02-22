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
 * awt_std.c
 *
 *  Created on: 22 mai 2009
 *      Author: lbarthelemy
 */

#include "awt_std.h"


#ifdef SYSTEM_OAT

#include <stdarg.h>
#include "wip.h"

void* _malloc( size_t size )
{
  void *ptr;
  ptr = adl_memGet( size );
  return ptr;
}

void _free( void *ptr )
{
  if( ptr != NULL )
    adl_memRelease( ptr );
}


// defines to support both Open AT SDK that defines malloc/free functions
// (like 2.34) or those that don't (like 2.33)
#pragma weak malloc = _malloc
#pragma weak free = _free

int printf(const char * fmt, ...){
//
  int res = 0;
  va_list ap;
  va_start  (ap, fmt);
  res = wip_debugv(fmt, &ap);
  va_end(ap);

  return res;
}

#endif
