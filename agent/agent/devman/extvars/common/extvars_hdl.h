/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Laurent Barthelemy for Sierra Wireless - initial API and implementation
 *     Fabien Fleutot     for Sierra Wireless - initial API and implementation
 *******************************************************************************/

#ifndef EXTVARSAPI_H_
#define EXTVARSAPI_H_

#include <lua.h>
#include "extvars.h"

typedef struct ExtVars_API_t {
  void                           *user_ctx;
  ExtVars_initialize_t           *initialize;
  Extvars_destroy_t              *destroy;
  ExtVars_get_variable_t         *get;
  ExtVars_get_variable_release_t *get_release;
  ExtVars_set_variables_t        *set;
  ExtVars_set_notifier_t         *set_notifier;
  ExtVars_list_t                 *list;
  ExtVars_list_release_t         *list_release;
  ExtVars_register_variable_t    *register_var;
  ExtVars_register_all_t         *register_all;
} ExtVars_API_t;

/* Pushes a treemgr handler object, wrapping the C functions in `api`,
 * on the Lua stack.
 *
 * @param L Lua state
 * @param module_name the Lua module's name; if NULL, the name is
 *        retrieved as the 1st element of the Lua stack, which must
 *        then be a string.
 * @param api the C functions implementing the handler.
 * @return 1 (because there's one value pushed on the stack as a result)
 */
int ExtVars_return_handler(struct lua_State *L, const char *module_name, const struct ExtVars_API_t* api);

#endif /* EXTVARSAPI_H_ */
