#!/bin/bash

#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- f1c100s_nano_linux_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4 INSTALL_MOD_PATH=out modules	
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4 INSTALL_MOD_PATH=out modules_install
