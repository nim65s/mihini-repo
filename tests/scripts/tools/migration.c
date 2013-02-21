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

#include "lua.h"
#include "lauxlib.h"
#include "swi_loh.h"
#include "migration.h"

#define MIGRATIONSCRIPT 1

int execute(lua_State* L){
  size_t vFromSize=0, vToSize=0;
  const char* vFrom = luaL_checklstring(L, 1, &vFromSize);
  const char* vTo = luaL_checklstring(L, 2, &vToSize);

  SWI_LOG("MIGRATIONSCRIPT", DEBUG, "execute: vFrom=[%s], vTo[%s]\n", vFrom, vTo);

  return 0;
}

static const luaL_Reg R[] =
{
{ "execute", execute },
{ NULL, NULL }
};

int luaopen_agent_migration(lua_State* L)
{
  luaL_register(L, "agent.migration", R);
  return 1;
}
