#!/bin/sh

#*******************************************************************************
# Copyright (c) 2012 Sierra Wireless and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Sierra Wireless - initial API and implementation
#*******************************************************************************

BASEDIR=$(cd $(dirname $0) && pwd)
cd $BASEDIR


rm -rf Lua_User_API_doc
rm -rf doctmp
rm -rf luadocumentor

mkdir doctmp

HOME_RA=$(cd $BASEDIR/../.. && pwd)

#echo "BASEDIR=$BASEDIR"
#echo "HOME_RA=$HOME_RA"

mkdir doctmp/utils
mkdir doctmp/utils/ltn12

ln -s $HOME_RA/luafwk/sched/init.lua doctmp/sched.lua
ln -s $HOME_RA/luafwk/log/init.lua doctmp/log.lua
ln -s $HOME_RA/luafwk/utils/path.lua doctmp/utils/path.lua
ln -s $HOME_RA/luafwk/utils/table.lua doctmp/utils/table.lua
ln -s $HOME_RA/luafwk/utils/loader.lua doctmp/utils/loader.lua
ln -s $HOME_RA/luafwk/utils/ltn12/source.lua doctmp/utils/ltn12/source.lua
ln -s $HOME_RA/luafwk/checks/checks.c doctmp/checks.c
ln -s $HOME_RA/luafwk/serial/serial.lua doctmp/serial.lua
ln -s $HOME_RA/luafwk/persist/qdbm.lua doctmp/persist.lua
ln -s $HOME_RA/luafwk/lpack/lpack.c doctmp/lpack.c
ln -s $HOME_RA/luafwk/serialframework/modbus/modbus.lua doctmp/modbus.lua
ln -s $HOME_RA/luafwk/serialframework/modbus/modbustcp.lua doctmp/modbustcp.lua
ln -s $HOME_RA/luafwk/timer.lua doctmp/timer.lua
ln -s $HOME_RA/luafwk/niltoken.lua doctmp/niltoken.lua

mkdir doctmp/airvantage

ln -s $HOME_RA/luafwk/racon/init.lua doctmp/airvantage.lua
ln -s $HOME_RA/luafwk/racon/asset/init.lua doctmp/airvantage/asset.lua
ln -s $HOME_RA/luafwk/racon/system.lua doctmp/system.lua
ln -s $HOME_RA/luafwk/racon/sms.lua doctmp/sms.lua
ln -s $HOME_RA/luafwk/racon/table.lua doctmp/airvantage/table.lua
ln -s $HOME_RA/luafwk/racon/devicetree.lua doctmp/devicetree.lua



ln -s $HOME_RA/luafwk/liblua/lua.luadoc doctmp/lua.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/coroutine.lua doctmp/liblua/coroutine.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/debug.lua doctmp/liblua/debug.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/global.lua doctmp/liblua/global.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/io.lua doctmp/liblua/io.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/math.lua doctmp/liblua/math.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/os.lua doctmp/liblua/os.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/package.lua doctmp/liblua/pakage.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/string.lua doctmp/liblua/string.lua
# ln -s $HOME_RA/luafwk/linux/liblua/luadoc/table.lua doctmp/liblua/table.lua


#mkdir doctmp/socket
#mkdir doctmp/socket/socket

ln -s $HOME_RA/luafwk/luasocket/luasocket.luadoc doctmp/socket.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/socket.lua doctmp/socket/socket.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/mime.lua doctmp/socket/mime.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/ltn12.lua doctmp/socket/ltn12.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/socket/url.lua doctmp/socket/socket/url.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/socket/http.lua doctmp/socket/socket/http.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/socket/smtp.lua doctmp/socket/socket/smtp.lua
# ln -s $HOME_RA/luafwk/common/luasocket/linux/luadoc/socket/ftp.lua doctmp/socket/socket/ftp.lua


#mkdir doctmp/lfs

ln -s $HOME_RA/luafwk/lfs/lfs.luadoc doctmp/lfs.lua

mkdir Lua_User_API_doc

# mkdir doc/luafwk
# mkdir doc/airvantage
# mkdir doc/liblua
# mkdir doc/socket
# mkdir doc/lfs

mkdir luadocumentor

if (uname -a | grep -q x86_64) ; then echo using luadocumentor-64bits.zip; ZIP=luadocumentor-64bits.zip ; else echo using luadocumentor-32bits.zip ;ZIP=luadocumentor-32bits.zip; fi

unzip $ZIP -d luadocumentor > /dev/null 2>&1

cd luadocumentor
lua luadocumentor.lua -d ../Lua_User_API_doc/ ../doctmp
# lua luadocumentor.lua -d ../doc/airvantage ../doctmp/airvantage
# lua luadocumentor.lua -d ../doc/liblua ../doctmp/liblua
# lua luadocumentor.lua -d ../doc/socket ../doctmp/socket
# lua luadocumentor.lua -d ../doc/lfs ../doctmp/lfs

##lua documentor seems to change current dir
cd $BASEDIR
rm -rf doctmp
rm -rf luadocumentor
echo end doc gen
