

#CC=/home/axelh/aosp/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin/arm-eabi-
CC=/home/axelh/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
#CC=/home/axelh/aosp-l/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-

#DEFCONFIG=bbb-max3-nxp-android_defconfig
#DEFCONFIG=bbb-max3_defconfig
DEFCONFIG=omap2plus_defconfig
#DEFCONFIG=bbb-max3_defconfig


OPTIONS="-j4 ARCH=arm CROSS_COMPILE=$CC LOADADDR=0x80008000"
rm ~/tftp/*
#make $OPTIONS clean
#make $OPTIONS $DEFCONFIG
make $OPTIONS uImage
make $OPTIONS dtbs
#make $OPTIONS modules
#make $OPTIONS modules_install INSTALL_MOD_PATH=/media/axelh/filesystem/


cp ./arch/arm/boot/zImage ~/tftp
cp ./arch/arm/boot/uImage ~/tftp

#cp  ./arch/arm/boot/dts/am335x-boneblack-uda98xx-stub.dtb ~/tftp/am335x-boneblack.dtb
#cp  ./arch/arm/boot/dts/am335x-boneblack-uda98xx.dtb ~/tftp/am335x-boneblack.dtb
cp  ./arch/arm/boot/dts/am335x-boneblack.dtb ~/tftp/am335x-boneblack.dtb





