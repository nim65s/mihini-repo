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

#include "swi_statusname.h"
#include <string.h> // strcmp(),
#include <stdlib.h> // bsearch(), qsort()
#include <assert.h>

struct num_name_t { swi_status_t num; const char *name; };

#define MAKE_STATUS( X) { SWI_STATUS_##X, #X }

/* number -> name correspondence table, sorted by increasing numbers. */
static const struct num_name_t num_names[] = {

  MAKE_STATUS( OK),

  // System related status codes
  MAKE_STATUS( UNKNOWN_ERROR),
  MAKE_STATUS( ASYNC),
  MAKE_STATUS( BUSY),
  MAKE_STATUS( ALLOC_FAILED),
  MAKE_STATUS( NOT_ENOUGH_MEMORY),
  MAKE_STATUS( RESOURCE_INITIALIZATION_FAILED),
  MAKE_STATUS( RESOURCE_NOT_INITIALIZED),
  MAKE_STATUS( CONTEXT_IS_CORRUPTED),
  MAKE_STATUS( READ_BUFFER_EOS),
  MAKE_STATUS( CORRUPTED_BUFFER),
  MAKE_STATUS( WRONG_PARAMS),
  MAKE_STATUS( EMPTY),
  MAKE_STATUS( SERVICE_UNAVAILABLE),
  MAKE_STATUS( ASYNC_FORBIDDEN_CALL),
  MAKE_STATUS( UNKNOWN_COMMAND),
  MAKE_STATUS( OPERATION_FAILED),

  MAKE_STATUS( INVALID_PATH),

  // AwtDa protocol object related status codes
  MAKE_STATUS( OBJECT_NOT_INITIALIZED),
  MAKE_STATUS( INVALID_OBJECT_TYPE),
  MAKE_STATUS( INVALID_OBJECT_CONTENT),
  MAKE_STATUS( NOT_A_LIST),
  MAKE_STATUS( NOT_A_MAP),
  MAKE_STATUS( ITEM_NOT_FOUND),
  MAKE_STATUS( BYTECODE_NOT_SUPPORTED),
  MAKE_STATUS( OBJECT_CREATION_FAILED),
  MAKE_STATUS( VALUE_OUT_OF_BOUND),

  // Network related error codes
  MAKE_STATUS( SERVER_UNREACHABLE),
  MAKE_STATUS( SERVER_FAILURE),
  MAKE_STATUS( IPC_READ_ERROR),
  MAKE_STATUS( IPC_WRITE_ERROR),
  MAKE_STATUS( IPC_TIMEOUT),
  MAKE_STATUS( IPC_BROKEN),

  // Serial related codes
  //MAKE_STATUS( SERIAL_ERROR), // synonym for UNKNOWN_ERROR
  //MAKE_STATUS( SERIAL_STACK_NOT_READY), // synonym for BUSY

  MAKE_STATUS( SERIAL_RESPONSE_TIMEOUT),
  MAKE_STATUS( SERIAL_RESPONSE_EXCEPTION),
  MAKE_STATUS( SERIAL_RESPONSE_INVALID_FRAME),
  MAKE_STATUS( SERIAL_RESPONSE_BAD_CHECKSUM),
  MAKE_STATUS( SERIAL_RESPONSE_INCOMPLETE_FRAME),
  MAKE_STATUS( SERIAL_RESPONSE_BAD_SLAVE),
  MAKE_STATUS( SERIAL_RESPONSE_BAD_FUNCTION),
  MAKE_STATUS( SERIAL_RESPONSE_SHORT_FRAME),

  //MAKE_STATUS( SERIAL_INIT_CONTEXT_NULL), // synonym for RESOURCE_NOT_INITIALIZED
  //MAKE_STATUS( SERIAL_INIT_NULL_POINTER), // synonym for ALLOC_FAILED
  MAKE_STATUS( SERIAL_INIT_CANNOT_CAPTURE_UART),
  MAKE_STATUS( SERIAL_INIT_CANNOT_SET_MESSAGE),
  //MAKE_STATUS( SERIAL_INIT_STACK_READY), // synonym for OK
  MAKE_STATUS( SERIAL_INIT_CANNOT_SET_FLOW_CONTROL),

  //MAKE_STATUS( SERIAL_REQUEST_PARAMETER_ERROR), // synonym for WRONG_PARAMS


  //Data Access related codes (Tree extension, etc)
  MAKE_STATUS( DA_NOT_FOUND),
  MAKE_STATUS( DA_BAD_TYPE),
  MAKE_STATUS( DA_BAD_CONTENT),
  MAKE_STATUS( DA_PERMISSION_REFUSED),
  MAKE_STATUS( DA_UNSUPPORTED_ACTION),
  MAKE_STATUS( DA_NODE)
};

#define N_STATUS (sizeof( num_names)/sizeof( struct num_name_t))


/* name -> number correspondence table, sorted by increasing alphabetical order.
 * Contrary to `num_names`, this is a table of pointers to structs, rather than
 * a table of structs. `bsearch` and `qsort` operations on this will therefore
 * require an extra indirection.
 *
 * The table is filled and sorted at runtime, the first time `swi_string2status()` is called.*/
static const struct num_name_t *name_nums[N_STATUS];

/* Set to true when `name_nums` has been filled and sorted. */
static int initialized = 0;

/* Comparison for `name_nums`'s `qsort()` and `bsearch()`.
 * Takes the extra pointer indirection into account. */
static int name_cmp( const void *a, const void *b) {
    struct num_name_t * const * nn_a=a, * const * nn_b=b;
    return strcmp( (*nn_a)->name, (*nn_b)->name);
}

/* Comparison for `num_names`'s `bsearch()`. */
static int num_cmp( const void *a, const void *b) {
    const struct num_name_t *nn_a=a, *nn_b=b;
    return  nn_a->num - nn_b->num;
}

/* Check that `num_name` is statically sorted; sorts `name_nums`. */
static void init() {
    int i;
    for(i=0; i<N_STATUS; i++) {
        name_nums[i] = & num_names[i];
        if( i>0) assert(num_names[i-1].num < num_names[i].num);
    }
    qsort( name_nums, N_STATUS, sizeof( struct num_name_t *), name_cmp);
    initialized = 1;
}

/* Converts a numeric status into a string, or returns NULL if not found. */
const char *swi_status2string( swi_status_t n) {
    struct num_name_t key = { n, NULL };
    struct num_name_t *found = bsearch( & key, num_names, N_STATUS, sizeof( struct num_name_t), num_cmp);
    if( found) return found->name;
    else return NULL;
}

/* Converts a status string into a numeric code, or returns 0 if not found. */
swi_status_t swi_string2status( const char *name) {
    if( ! initialized) init();
    struct num_name_t key_content = { 0, name };
    struct num_name_t *key = & key_content;
    struct num_name_t **found = bsearch( & key, name_nums, N_STATUS, sizeof( struct num_name_t *), name_cmp);
    if( found) return (*found)->num;
    else return 0;
}
