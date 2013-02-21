#/*******************************************************************************
# * Copyright (c) 2012 Sierra Wireless and others.
# * All rights reserved. This program and the accompanying materials
# * are made available under the terms of the Eclipse Public License v1.0
# * which accompanies this distribution, and is available at
# * http://www.eclipse.org/legal/epl-v10.html
# *
# * Contributors:
# *     Sierra Wireless - initial API and implementation
# *******************************************************************************/

if [ $# -ge 2 ]
then
    echo "Building target: $1"
    DESTDIR=$1
    RA_SVNDIR=$2
    OPTIONALAGENT=$3
    olddir=$(pwd)

    if [ -d $DESTDIR ]; then
         #nothing to do
         echo "Destination already exists ... Updating"
    else

         echo "Creating new destination"
         mkdir -p $DESTDIR
    fi

    cd $DESTDIR

    #cmake ReadyAgent
    cmake $RA_SVNDIR
    makeret=$?
    if [ $makeret -ne 0 ]; then
        cd $olddir
        echo "cmake error"
        exit $makeret
    fi

    make lua all
    makeret=$?
    if [ $makeret -ne 0 ]; then
        cd $olddir
        echo "make error: option is $OPTIONALAGENT"
        exit $makeret
    fi

    # delete the generic lua file
    rm -f runtime/lua/agent/migration.lua

    make $OPTIONALAGENT
    makeret=$?
    if [ $makeret -ne 0 ]; then
        cd $olddir
        echo "make error: option is $OPTIONALAGENT"
        exit $makeret
    fi

    #cp $OPTIONALAGENT runtime/lua

    cd $olddir
else
    echo "Specific ReadyAgent Destination not specified"
    echo "Use: script [Dest_Dir] [SVN_Dir] [Optional_Agent]"
    exit 1
fi


