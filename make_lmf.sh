#!/bin/bash

CODE_BASE_DIR=`pwd`
BUILD_DIR=$CODE_BASE_DIR

echo CODE_BASE_DIR : $CODE_BASE_DIR

if [ -f $CODE_BASE_DIR/autolinux.config ]; then 
    source $CODE_BASE_DIR/autolinux.config
else
    echo -e "\e[31m[ERROR] Can't find autolinux.config file.\e[0m"
    exit 0;
fi

echo MACHINE : $MACHINE

BUILD_DIR=$BUILD_DIR/build/$MACHINE/tmp/work

echo Build Directory : $BUILD_DIR 

find $BUILD_DIR -maxdepth 2 -name libcdk-audio