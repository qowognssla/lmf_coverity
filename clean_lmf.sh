#!/bin/bash
##CODE_BASE_DIR from tc_coverity.sh

BUILD_DIR=$CODE_BASE_DIR
MODULE=$1

echo CODE_BASE_DIR : $CODE_BASE_DIR

if [ -f $CODE_BASE_DIR/autolinux.config ]; then 
    source $CODE_BASE_DIR/autolinux.config
else
    echo -e "\e[31m[ERROR] Can't find autolinux.config file.\e[0m"
fi

echo MACHINE : $MACHINE

BUILD_DIR=$BUILD_DIR/build/$MACHINE/tmp/work

echo Build Directory : $BUILD_DIR 

MODULE_ROOT_PATH=`find $BUILD_DIR -maxdepth 2 -name $MODULE`
MODULE_SUB_PATH=`ls $MODULE_ROOT_PATH`
MODULE_PATH=$MODULE_ROOT_PATH/$MODULE_SUB_PATH

echo MODULE PATH : $MODULE_PATH
echo Selected MODULE is $MODULE

if [ $MODULE == "libcdk-audio" ]; then
    echo clean "libcdk-audio"
    cd $MODULE_PATH/build && make clean
elif [ $MODULE == "libomxil-telechips" ]; then
    echo clean "libomxil-telechips"
    cd $MODULE_PATH/git && make clean
elif [ $MODULE == "gstreamer1.0-plugins-telechips" ]; then
    echo clean "gstreamer1.0-plugins-telechips"
    cd $MODULE_PATH/git && make clean
elif [ $MODULE == "vpu_kernel_k54" ]; then
    echo clean "vpu_kernel_k54"
    ./make_vpu_k54.sh clean
elif [ $MODULE == "dvrs_media_framework" ]; then
    echo clean "dvrs_media_framework"
    make clean
elif [ $MODULE == "t-media-framework" ]; then
    echo clean "t-media-framework"
    cd $MODULE_PATH/git && make distclean
fi