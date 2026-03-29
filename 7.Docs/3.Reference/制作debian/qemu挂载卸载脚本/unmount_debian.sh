#!/bin/sh

sudo rm rootfs/usr/bin/qemu-arm-static
cd rootfs
sudo umount   dev/pts/
sudo umount   dev/
sudo umount   sys/
sudo umount   proc/
