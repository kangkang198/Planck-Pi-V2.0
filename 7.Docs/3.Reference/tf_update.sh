#!/bin/sh

sudo umount /dev/sdb1
sudo mount /dev/sdb1 ~/mnt/

sudo cp ./arch/arm/boot/zImage ~/mnt/
sudo cp ./arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dtb ~/mnt/

sudo umount /dev/sdb1

echo "tf_update ok"  
