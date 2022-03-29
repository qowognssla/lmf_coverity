#!/bin/bash

export GCC_TOOLCHAIN_DIR=/home/hoonbae/source/100.common/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin

export VPU_DIR=./drivers/char/vpu
export DRIVERS_DIR=./drivers/char/

export PATH=$PATH:$GCC_TOOLCHAIN_DIR
export ARCH=arm64
export CROSS_COMPILE="aarch64-none-linux-gnu-"
export CC=$CROSS_COMPILE"gcc"
export CXX=$CROSS_COMPILE"gcc++"
export ARCH64_EABI=1
export OS_BIT=64
unset HF_EABI

# 
#make tcc805x_linux_ivi_defconfig

echo Toolchain dir = $GCC_TOOLCHAIN_DIR
echo VPU_DIR = $VPU_DIR

CMD_COUNT=$#

if [ $CMD_COUNT -eq 0 ]
then 
    echo try to make build
    make $VPU_DIR/
else
    while (( "$CMD_COUNT" ));
    do
        case "$1" in
            clean)
                echo clean objects
                touch $VPU_DIR/*
                find $VPU_DIR -name "*.o" -exec rm -rf {} \;
                find $VPU_DIR -name "*.cmd" -exec rm -rf {} \;
                find $VPU_DIR -name "*.ko" -exec rm -rf {} \;
                find $VPU_DIR -name "*.mod" -exec rm -rf {} \;
                find $VPU_DIR -name "*.mod.c" -exec rm -rf {} \;
                find $VPU_DIR -name "modules.order" -exec rm -rf {} \;
                exit 1
                ;;
            *)
                echo Not support commend
                exit 0
                ;;
        esac
    done
fi