#!/bin/sh

#*******************************************************************************
# Copyright (c) 2012 Sierra Wireless and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Romain Perier for Sierra Wireless - initial API and implementation
#*******************************************************************************


luavm=lua
lua_version=`${luavm} -e 'print(_VERSION)' | cut -d ' ' -f 2`
version=0.12.1
tarball=LuaSrcDiet-${version}.tar.bz2

fail() {
    echo "FAIL!"
    exit 1
}

if [ $# != 1 ]; then
    echo "Usage: compress-build-artifacts [build_artifacts_dir]"
    exit 1
fi

if [ ! -d luasrcdiet ]; then
    if [ ! -e ${tarball} ]; then
        wget https://luasrcdiet.googlecode.com/files/${tarball} || exit 1
    fi
    tar xapf ${tarball} || exit 1
    mv LuaSrcDiet-${version}/src luasrcdiet || exit 1
    rm -rf LuaSrcDiet-${version}
fi

# For some distributions like Arch Linux, /usr/bin/lua is the lastest Lua (5.2 for now).
# We want only Lua 5.1 here
if [ "$lua_version" != "5.1" ]; then
	which lua5.1 2>&1 >/dev/null

	if [ $? != 0 ]; then     
	    echo "Lua 5.1 is required !"
	    echo "Found version ${lua_version}"
	    exit 1
	fi
	luavm=lua5.1
	lua_version=`${luavm} -e 'print(_VERSION)' | cut -d ' ' -f 2`
fi

echo "Found LuaVM ${lua_version}"
cd luasrcdiet
for i in $(find $1 -name '*.lua'); do
    cp $i tmp.lua
    echo -n "Compressing $i..."
    ${luavm} LuaSrcDiet.lua --maximum tmp.lua -o $i 2>&1 >/dev/null || fail
    echo "Ok"
done
rm -f tmp.lua
cd ..
