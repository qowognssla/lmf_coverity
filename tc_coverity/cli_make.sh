#!/bin/bash

while (( "$#" )); do
    case "$1" in
        omx)
            echo "Try build libomxil-telechips"
            if [ -f $CODE_BASE_DIR/autolinux ]; then
                $CODE_BASE_DIR/autolinux -c build libomxil-telechips
            else
                bitbake libomxil-telechips
            fi
            exit 1
            ;;
        plugins)
            echo "Try build gstreamer1.0-plugins-telechips"
            if [ -f $CODE_BASE_DIR/autolinux ]; then
                $CODE_BASE_DIR/autolinux -c build gstreamer1.0-plugins-telechips
            else
                bitbake gstreamer1.0-plugins-telechips
            fi
            exit 1
            ;;
        cdk)
            echo "Try build libcdk-audio"
            if [ -f $CODE_BASE_DIR/autolinux ]; then
                $CODE_BASE_DIR/autolinux -c build libcdk-audio
            else
                bitbake libcdk-audio
            fi    
            exit 1
            ;;
    esac
done