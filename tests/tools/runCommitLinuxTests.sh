#!/bin/bash

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

# Choose where to build
if [ $# -gt 0 ]; then
    DESTDIR=$1

elif [ ! -z "$PLATFORM_EMBEDDED_TEST_DESTDIR" ]; then
    echo "Building in \$PLATFORM_EMBEDDED_TEST_DESTDIR==$PLATFORM_EMBEDDED_TEST_DESTDIR"
    DESTDIR=$PLATFORM_EMBEDDED_TEST_DESTDIR

else
    NOW=$(date +"%Y%m%d%H%M%S")
    DESTDIR=~/testsRA$NOW
fi

INITIAL_WD=$(pwd)
cd $(dirname $0)

#store the SVN directory of ReadyAgent
RA_SVNDIRTEST=$(pwd)
RA_SVNDIR=$RA_SVNDIRTEST/../..

#create and move to destination dir
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

#Build ReadyAgent and tests suites
make embeddedtests lua all
makeret=$?
if [ $makeret -ne 0 ]; then
    echo "Make error"
    exit $makeret
fi

#copy shell scripts
cp $RA_SVNDIRTEST/startTests.sh runtime
cp $RA_SVNDIRTEST/startNewAgent.sh runtime


echo "Environment ready - starting tests"
#run tests
#change working directory into lua directory
cd runtime/lua

#start lua program
../bin/lua ./tests/managers/startOnCommitTests.lua

testret=$?

#restore initial working dir
cd $INITIAL_WD

if [ $testret -ne 0 ]; then
    echo "Tests execution error"
    exit $testret
fi

