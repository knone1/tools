#!/bin/bash

TOP=`pwd`
ARCH=x86
LINUXVER=3.0.34
BOARD=$1
LINUXDIR=${TOP}/hardware/intel/linux-2.6
PRODUCT_OUT=${TOP}/out/target/product/${BOARD}
KERNEL_BUILD_DIR=${PRODUCT_OUT}/axel_kernel    
BCMDHD_SRC_DIR=${TOP}/hardware/broadcom/PRIVATE/wlan/bcm43xx/open-src/src/dhd/linux
MODULE_DEST=${PRODUCT_OUT}/axel_ramdisk/lib/modules
TARGET=dhd-cdc-sdmmc-android-panda-icsmr1-cfg80211-oob

function exit_on_error {
    if [ "$1" -ne 0 ]; then
        exit 1
    fi
}

make_bcmdhd() {
    echo "Making bcmdhd wireless for ${BOARD}"
    echo "-----------------------------------"

    cd ${BCMDHD_SRC_DIR}
    make ARCH=${ARCH} K_BUILD=${KERNEL_BUILD_DIR} LINUXDIR=${LINUXDIR}/ LINUXVER=${LINUXVER} O=${KERNEL_BUILD_DIR}/ ${TARGET}
    exit_on_error $? quiet
    cp -f ${BCMDHD_SRC_DIR}/${TARGET}-${LINUXVER}/bcmdhd.ko ${MODULE_DEST}
    cd ${TOP}
}

main() {
    make_bcmdhd
    exit_on_error $?
    exit 0
}

exec 3>&2
exec 2>&1
main

