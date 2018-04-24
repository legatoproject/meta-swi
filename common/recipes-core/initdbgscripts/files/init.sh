#!/bin/sh
# Copyright 2018 Sierra Wireless
#
# Script to set the environment valuable of debug image

usage()
{
    cat << EOF
Usage:
source init.sh <image_mount_dir>
EOF
}

if [ $# = 0 ]; then
    usage
else
    IMAGE_DIR=$(cd $1; pwd)
    if [ -d ${IMAGE_DIR} ]; then
        export "PATH=${IMAGE_DIR}/usr/bin:${IMAGE_DIR}/usr/sbin:${PATH}"

        # Add path for share libraries
        export "LD_LIBRARY_PATH=${IMAGE_DIR}/lib:${IMAGE_DIR}/usr/lib:${LD_LIBRARY_PATH}"

        # Environment for systemtap
        export SYSTEMTAP_STAPIO=${IMAGE_DIR}/usr/libexec/systemtap/stapio
    else
        echo "${IMAGE_DIR} is not a directory."
    fi
fi


