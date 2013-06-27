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

while getopts g: o
do  case "$o" in
    g)  ga_tracker_path="$OPTARG";;
    ?)  print "Usage: $0 [-g ga_tracker_path]"
        exit 1;;
    esac
done

if [ -n "$ga_tracker_path" ]; then
    doxygen -w html headertmp tmp1 tmp2 Doxyfile

    sed "\,</head>, {
            h
            r $ga_tracker_path
            g
            N
    }" headertmp > header
       
else
doxygen -w html header tmp1 tmp2 Doxyfile
fi

#cleanup
rm -rf tmp1 tmp2 headertmp

