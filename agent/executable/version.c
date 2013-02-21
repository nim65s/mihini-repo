/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Cuero Bugot for Sierra Wireless - initial API and implementation
 *******************************************************************************/

#include "version.h"


// If the SVN Revision is known
#ifndef GIT_REV
    #define GIT_REV "Unknown"
#endif //not GIT_REV

int luaopen_agent_versions(lua_State *L)
{
    lua_pushstring(L, READYAGENT_MAJOR_VERSION "." READYAGENT_MINOR_VERSION " - Build: " GIT_REV);
    lua_setglobal(L, "_READYAGENTRELEASE");
    lua_pushstring(L, LUA_RELEASE);
    lua_setglobal(L, "_LUARELEASE");
    push_sysversion(L);
    lua_setglobal(L, "_OSVERSION");

    return 0;
}

