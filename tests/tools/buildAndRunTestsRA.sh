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

#!/bin/sh
if [ $# -gt 0 ]
then
    DESTDIR=$1
else
    NOW=$(date +"%Y%m%d%H%M%S")
    DESTDIR=~/testsRA$NOW
fi

#store the SVN directory of ReadyAgent
RA_SVNDIRTEST=$(pwd)
RA_SVNDIR=$RA_SVNDIRTEST/../..

#create and move to destination dir
if [ -d $DESTDIR ]; then
    #nothing to do
    echo "Destination already exists ... Updating"
else
    echo "Creating new destination"
    mkdir $DESTDIR
fi

cd $DESTDIR

#cmake ReadyAgent
cmake $RA_SVNDIR

#Build ReadyAgent and tests suites
make embeddedtests lua all

# copy "run" files for Application Container tests
mkdir -p runtime/externalapp/appconlua
cp $RA_SVNDIRTEST/lua/runAppCon.lua runtime/externalapp/appconlua/run
chmod +x runtime/externalapp/appconlua/run

mkdir -p runtime/externalapp/appconcrashlua
cp $RA_SVNDIRTEST/lua/crashAppCon.lua runtime/externalapp/appconcrashlua/run
chmod +x runtime/externalapp/appconcrashlua/run


mkdir -p runtime/externalapp/appconsh
cp $RA_SVNDIRTEST/misc/test_no_catch.sh runtime/externalapp/appconsh/run
chmod +x runtime/externalapp/appconsh/run

mkdir -p runtime/externalapp/appconshcatchsigterm
cp $RA_SVNDIRTEST/misc/test_catch_sigterm_and_quit.sh runtime/externalapp/appconshcatchsigterm/run
chmod +x runtime/externalapp/appconshcatchsigterm/run

mkdir -p runtime/externalapp/appconshignoresigterm
cp $RA_SVNDIRTEST/misc/test_catch_sigterm.sh runtime/externalapp/appconshignoresigterm/run
chmod +x runtime/externalapp/appconshignoresigterm/run

#copy shell scripts
cp $RA_SVNDIRTEST/startTests.sh runtime
cp $RA_SVNDIRTEST/startNewAgent.sh runtime

#Build ReadyAgent for migration (without and with lua and c)
$RA_SVNDIRTEST/buildSpecificAgent.sh $DESTDIR/specific/migrationwithout $RA_SVNDIR testsmigrationwithout
$RA_SVNDIRTEST/buildSpecificAgent.sh $DESTDIR/specific/migrationlua $RA_SVNDIR testsmigrationhelperlua
$RA_SVNDIRTEST/buildSpecificAgent.sh $DESTDIR/specific/migrationc $RA_SVNDIR testsmigrationhelperc

echo "Running tests"
#run tests
cd runtime/lua
../bin/lua ./tests/managers/starttests.lua
