# Planck-Pi开发指南

参考博客：
```
https://wiki.sipeed.com/soft/Lichee/zh/Nano-Doc-Backup/index.html
```

# 0.在TF卡上构建系统
在前文我们已经成功构建了 bootloader，我们接下来需要放进TF卡的内容有：


第一分区：
```
zImage
suniv-f1c100s-licheepi-nano.dtb
```
第二分区：
```
rootfs根文件系统
```
在TF卡上构建系统之前，我们需要将TF卡进行分区与格式化；


命令行方式如下，首先查看电脑上已插入的TF卡的设备号（一般为 /dev/sdb1,下面以/dev/sdb1为例：

```
sudo fdisk -l 
```

若自动挂载了TF设备，先卸载（有多个分区则全部卸载）：

```
sudo umount /dev/sdb1 /dev/sdb2 ...
```

进行分区操作：

```
sudo fdisk /dev/sdb
```

操作步骤如下：

1. 若已存分区即按 d 删除各个分区

2. 通过 n 新建分区，第一分区暂且申请为128M用于储存Linux内核，剩下的空间都给root-fs

	> * **第二分区操作**：p 主分区、1 分区、默认2048、+128M
	>
	>   ```
	>   n p [Enter] [Enter] [Enter] +128M
	>   ```
	>
	> * **第三分区操作**：p 主分区、2 分区、默认2048，剩下的全部分配
	>
	>   ```
	>   n p [Enter] [Enter] [Enter] [Enter]
	>   ```
	>
	> * w 保存写入并退出

分区格式化：

```
sudo mkfs.vfat /dev/sdb1 # 将第1分区格式化成FAT
sudo mkfs.ext4 /dev/sdb2 # 将第2分区格式化成EXT4  
```

# 1.安装编译工具链

> **注意：**GCC版本要大于 6；此处为获取交叉编译链为7.5.0版本，也可以自行下载其他版本。

将工具链压缩包解压：

```  
 mkdir /usr/local/arm 
 sudo tar -vxf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz -C /usr/local/arm 
```

配置环境变量：

```
vim  ~/.bashrc
```

打开文件添加下面的变量：

```
export PATH=$PATH:/usr/local/arm/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi/bin
```

使环境变量立即生效 ：

```
source ~/.bashrc 
```

查询版本，确认安装成功 ：

```
arm-linux-gnueabi-gcc -v
```

接下来安装依赖的软件包：

```
sudo apt-get install xz-utils nano wget unzip build-essential git bc swig libncurses5-dev libpython3-dev libssl-dev pkg-config zlib1g-dev libusb-dev libusb-1.0-0-dev python3-pip gawk bison flex python-dev
```

# 2.编译 u-boot
下载链接：
```
https://gitee.com/LicheePiNano/u-boot.git
```

```
sudo vim build_uboot.sh
```
内容如下：
```
#!/bin/bash
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- licheepi_nano_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
```

```
sudo chmod 777 build_uboot.sh
```
开始编译：
```
./build_uboot.sh
```
编译完成后，可一看到目录下多了一堆以u-boot带头的文件，我们只需取
u-boot-sunxi-with-spl.bin 即可；

```
sudo dd if=./u-boot-sunxi-with-spl.bin of=/dev/sdb bs=1024 seek=8
sync
```

> **注意：**这里的`bs=1024 seek=8`是添加了8192字节的偏移，之所以要加8K偏移是因为FSBL也就是bootROM里面硬写死了会从设备的8K地址处加载SPL，然后进入uboot。因此上面烧写的时候，指定的偏移地址一定是**相对于储存设备硬件的偏移，而不是相对于分区的偏移**！
>
> * 8K的来源是参考`buildroot-mangopi-r/board/allwinner/generic/genimage-sdcard.cfg`文件的描述`offset = 0x2000`。

```
setenv bootargs 'console=tty1 console=ttyS0,115200 panic=5 rootwait root=/dev/mmcblk0p2 rw'
setenv bootcmd 'load mmc 0:1 0x80008000 zImage; load mmc 0:1 0x80C00000 suniv-f1c100s-licheepi-nano.dtb; bootz 0x80008000 - 0x80C00000'
saveenv
```

# 3.主线Linux编译
下载链接
```
https://gitee.com/LicheePiNano/Linux.git
```
```
sudo vim build_kernel.sh
```
内容如下：
```
#!/bin/bash
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- f1c100s_nano_linux_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4 INSTALL_MOD_PATH=out modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4 INSTALL_MOD_PATH=out modules_install
```
```
sudo chmod 777 build_kernel.sh
```
开始编译：
```
./build_kernel.sh
```
编译成功后，生成文件所在位置：

```
内核img文件：./arch/arm/boot/zImage
设备树dtb文件:./arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dtb
modules文件夹：./out/lib/modules
将zImage与dtb文件放入nano第一分区．
```


# 4.使用buildroot构建根文件系统
buildroot可用于构建小型的linux根文件系统。

大小最小可低至2M，与内核一起可以放入最小8M的spi flash中。

buildroot中可以方便地加入第三方软件包（其实已经内置了很多），省去了手工交叉编译的烦恼。

首先安装一些依赖，比如linux头文件：
```
sudo apt-get install linux-headers-$(uname -r)
```

下载链接:
```
https://buildroot.org/downloads/buildroot-2021.02.4.tar.gz
```
```
tar xvf buildroot-2021.02.4.tar.gz
cd buildroot-2021.02.4/
make menuconfig
```

```
以下选项为基础配置：

- Target options
  - Target Architecture (ARM (little endian))
  - Target Variant arm926t
- Toolchain
  - C library (musl) # 使用musl减小最终体积
- System configuration
  - Use syslinks to /usr .... # 启用/bin, /sbin, /lib的链接
  - Enable root login # 启用root登录
  - Run a getty after boot # 启用登录密码输入窗口
  - (licheepi) Root password #　默认账户为root 密码为licheepi

另可自行添加或删除指定的软件包
```
一些配置的简单说明:
```
Target options  --->

    Target Architecture Variant (arm926t)  --->   // arm926ejs架构
[ ] Enable VFP extension support                  // Nano 没有 VFP单元，勾选会导致某些应用无法运行
    Target ABI (EABI)  --->
    Floating point strategy (Soft float)  --->    // 软浮点

System configuration  --->

    (Lichee Pi) System hostname                   // hostname
    (licheepi) Root password                      // 默认账户为root 密码为licheepi
    [*] remount root filesystem read-write during boot  // 启动时重新挂在文件系统使其可读写 

```

```
sudo vim build_rootfs.sh
```

```
#!/bin/bash
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
```

```
sudo chmod 777 build_rootfs.sh
```
开始编译：
```
./build_rootfs.sh
```

有时候构建会出现莫名其妙的错误，make clean下会ok？
编译的过程如果带上下载软件包的时间比较漫长，很适合喝杯茶睡个午觉；(buildroot不能进行多线程编译)

编译完成的镜像包，是
buildroot-2021.02.4/output/images/rootfs.tar


将镜像包复制到第二分区后，解压即可
```
cd

mkdir mnt

sudo umount /dev/sdb2
sudo mount /dev/sdb2 ~/mnt
sudo cp ./rootfs.tar ~/mnt
sudo tar -xf ~/mnt/rootfs.tar
sudo rm ~/mnt/rootfs.tar
sync
sudo umount /dev/sdb2
```

另：检查 rootfs文件下的 /etc/inittab 是否已有以下声明：
```
ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100 # GENERIC_SERIAL // 串口登录使能
```