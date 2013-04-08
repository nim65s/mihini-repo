/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Fabien Fleutot for Sierra Wireless - initial API and implementation
 *******************************************************************************/

/* Convert between string status and numeric status. */

#ifndef SWI_STATUSNAME_H_INCLUDED
#define SWI_STATUSNAME_H_INCLUDED

#include <swi_status.h>

const char *swi_status2string( swi_status_t n);
swi_status_t swi_string2status( const char *name);

#endif
