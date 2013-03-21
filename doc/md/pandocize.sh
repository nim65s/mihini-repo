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
    ConfigStore.md
"

if [ $# != 1 ]; then
    source_dir="."
else
    source_dir="$1"
fi

for md in $markdown_list; do
    output=$(echo $md | sed 's:\.md::')
    output_dir=$(echo $md | sed 's:/.*::')
    test -d $output_dir || mkdir $output_dir
    pandoc --standalone --highlight-style=tango ${source_dir}/$md -o ${output}.html || exit 1
done
