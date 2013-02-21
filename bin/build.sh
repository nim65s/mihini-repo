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

# Usage:
# build.sh <build target>


EXEC_DIR=$(pwd)
BIN_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(dirname $BIN_DIR)
CMAKE_DIR=$ROOT_DIR/cmake
SOURCECODE_DIR=$ROOT_DIR

DEBUG=
TARGET=default

while getopts 'dt:C:' OPTION
do
    case $OPTION in
    d)    DEBUG=1
          echo '>>> Set DEBUG option to TRUE'
                ;;
    t)    TARGET="$OPTARG"
          echo ">>> Set TARGET type to $OPTARG"
                ;;
    C)    BUILD_DIR="$OPTARG"
          echo ">>> Set BUILD DIRECTORY to $OPTARG"
                ;;
    *)    printf "Usage: %s: [-d] [-t target]\n" $(basename $0) >&2
            exit 2
                ;;
    esac
done

if [ ! $BUILD_DIR ] 
then
  BUILD_DIR=$(pwd)/build.$TARGET
  echo ">>> Set BUILD DIRECTORY to default value: $BUILD_DIR"
fi

# go into the root directory
cd $ROOT_DIR
ret=$?
if [ $ret -ne 0 ]
then
    echo "Command \"cd $ROOT_DIR\" failed"
    exit $ret
fi

# check if the target exist
if [ ! -e $CMAKE_DIR/toolchain.$TARGET.cmake ]
then
    echo "No toolchain file found for target \"$TARGET\"" >&2
    exit 2
fi

#look for source directory
SOURCECODE_DIR=$ROOT_DIR

#clean build directory
if [  -d $BUILD_DIR ]
then
    rm -fr $BUILD_DIR
    ret=$?
    if [ $ret -ne 0 ]
    then
        echo "Command \"rm -fr $BUILD_DIR\" failed"
        exit $ret
    fi
fi

mkdir -p $BUILD_DIR
ret=$?
if [ $ret -ne 0 ]
then
    echo "Command \"mkdir -p $BUILD_DIR\" failed"
    exit $ret
fi

cd $BUILD_DIR
ret=$?
if [ $ret -ne 0 ]
then
    echo "Command \"cd $BUILD_DIR\" failed"
    exit $ret
fi

#launch cmake
CMAKE_OPT=-DCMAKE_TOOLCHAIN_FILE=$CMAKE_DIR/toolchain.$TARGET.cmake
if [ $DEBUG ]
then
    CMAKE_OPT="$CMAKE_OPT -DCMAKE_BUILD_TYPE=Debug"
else
    CMAKE_OPT="$CMAKE_OPT -DCMAKE_BUILD_TYPE=Release"
fi

cmake $CMAKE_OPT $SOURCECODE_DIR
ret=$?
if [ $ret -ne 0 ]
then
    echo "Command \"cmake $CMAKE_OPT $SOURCECODE_DIR\" failed"
    exit $ret
fi


# Do the compilation
cores=$(getconf _NPROCESSORS_ONLN)
make -j${cores}
ret=$?
if [ $ret -ne 0 ]
then
    echo "Command \"make\" failed"
    exit $ret
fi
