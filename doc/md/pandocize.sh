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

markdown_list="
    agent/ConfigStore.md
    agent/Appmon_Daemon.md
    agent/security.md
    agent/Logging_framework.md
    agent/Migration.md
    agent/Network_Manager.md
    utilitary_libraries/Lua_RPC.md
    utilitary_libraries/Modbus.md
    ../../README.md
"

if [ $# != 1 ]; then
    source_dir="."
else
    source_dir="$1"
fi

for md in $markdown_list; do
    output=$(echo $md | sed 's:\.md::')
    category_dir=$(echo $md | sed 's:/.*::')
    test -d $category_dir || mkdir $category_dir

    if [ -d ${source_dir}/${category_dir}/images ]  && [ ! -e ${category_dir}/images ]; then
	ln -s ${source_dir}/${category_dir}/images ${category_dir}/images
    fi

    if [ ! -e default.css ]; then
        ln -s ${source_dir}/default.css default.css
    fi

    pandoc --standalone --css="../default.css" --highlight-style=tango ${source_dir}/$md -o ${output}.html || exit 1
done
