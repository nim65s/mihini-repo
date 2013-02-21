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

# Were the packaged copy will be put
WD_DST=${1:-/tmp/readyagent-$(date '+%y-%m-%d-%H-%M-%S')}
# Were the original copy is
WD_SRC=$(cd $(dirname $0)/.. && pwd)

if [ -x $WD_DST ] ; then
    echo "Erase target dir $WD_DST first" >2
    exit -1
elif ! mkdir $WD_DST ; then
    echo "Cannot create target dir" >2
    exit -2
fi

echo "Generating package in $WD_DST from $WD_SRC"

# Folders & files to actually copy
DIRS="agent bin cfwk cmake doc libs luafwk tests CMakeLists.txt"

# Copy folders to package
mkdir -p $WD_DST
cd $WD_SRC && cp -r $DIRS $WD_DST

# Get rid of archives copied from LDT, which are under EPL anyway.
rm  $WD_DST/doc/ldoc/luadocumentor*.zip


# Folders are moved there rather than erased
SAVE_DIR=$WD_DST/saved
# Where zipped 3rd party folders go
ZIP_DIR=$WD_DST/3rd_party

mkdir -p $SAVE_DIR
mkdir -p $ZIP_DIR
cd $WD_DST


# Compress folders which contain a README.CQ file into a zip,
# move the zip in the $ZIP_DIR folder, and only keep a file mentioning
# that a different CQ has been made for the folder.
for F in $(find . -name README.CQ); do
    THIRD_PARTY_DIR=$(dirname $F)
    DIR_NAME=$(basename $THIRD_PARTY_DIR)
    echo "Handling $DIR_NAME $THIRD_PARTY_DIR"
    cd $THIRD_PARTY_DIR/..
    zip -q -r $DIR_NAME.zip $DIR_NAME -x "*README.CQ*"
    mv $DIR_NAME.zip $ZIP_DIR
    mv $DIR_NAME $SAVE_DIR
    mkdir $DIR_NAME
    echo "This folder has been contributed in a separate CQ." > $DIR_NAME/README.CQ
    cd $WD_DST
done

echo "result in directory $WD_DST"
echo "don't forget to delete $SAVE_DIR"