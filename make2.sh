#!/bin/bash 
PP=$@

DESC=$1
time1=`date`


###############################################################################
#	SOME SETTINGS
###############################################################################


echo "***************************"
echo "        PARAMETERS"
echo "***************************"

BUILD=4430sdp32
MODULES=OFF
DEFCONFIG=ON
CLEAN=OFF
BUILD_KERNEL=ON
FILE_SYSTEM=4430_android

echo "Building for :"$BUILD
echo "MODULES :"$MODULES
echo "DEFCONFIG :"$DEFCONFIG
echo "CLEAN :"$CLEAN
echo "BUILD_KERNEL":$BUILD_KERNEL

case $BUILD in 
"kernel-omap3")CONFIG=omap_3630sdp_defconfig;;
"3630sdp32")CONFIG=omap_3630sdp_defconfig;;
"3630zoom32")CONFIG=android_zoom3_defconfig;;
"3630zoom29")CONFIG=zoom3_defconfig;;
"3630sdp29")CONFIG=omap_3630sdp_defconfig;;
"4430sdp32")CONFIG=android_4430_defconfig;;
"3430sdp29")CONFIG=zoom2_defconfig;;
"4430sdp32_ES2")CONFIG=android_4430_defconfig;;
"L24")CONFIG=omap_4430sdp_defconfig;;
"L24_B")CONFIG=omap_4430sdp_defconfig;;
4430sdp35)CONFIG=android_4430_defconfig;;
esac

case $FILE_SYSTEM in
	"busybox")FS_LINK=./busybox2;;
	"eclair")FS_LINK=./myfs_eclair;;
	"donut")FS_LINK=./donut;;
	"4430_android")FS_LINK=/home/axel/export/myfs_BR_L27.3_RC1;
esac

if [ $FILE_SYSTEM == "busybox" ];then
	case $BUILD in 
	"kernel-omap3")INITTAB=inittab.S0;;
	"3630sdp32")INITTAB=inittab.O0;;
	"3630zoom32")INITTAB=inittab.O3;;
	"3630zoom29")INITTAB=inittab.S3;;
	"3630sdp29")INITTAB=inittab.S0;;
	"4430sdp32")INITTAB=inittab.O2;;
	esac
fi


if [ ! -d ~/p-android/$BUILD ]; then
	echo "no project for that processor-platform-kernel!"
	exit
fi 

cd ~/p-android/$BUILD

###############################################################################
#			MAKE THE KERNEL
###############################################################################
if [ $BUILD_KERNEL == "ON" ];then

# remove the old kernel 
# in case the build fails. 
# we dont get a link to the "old" kernel
rm ./arch/arm/boot/uImage

if [ $CLEAN == "ON" ];then
	
	echo "***************"
	echo "CLEAN KERNEL"
	echo "***************"
	make distclean
fi

if [ $DEFCONFIG == "ON" ];then
	echo "***************"
	echo "USING DEFAULT MENUCONFIG OPTIONS"
	echo "***************"
	cp ./.config ./config.bkp
	make ARCH=arm CROSS_COMPILE=~/arm-2008q3/bin/arm-none-linux-gnueabi- $CONFIG
fi

echo "***************"
echo "MAKING KERNEL"
echo "***************"

#ELECTRIC CLUOD TEST
#/opt/ecloud/i686_Linux/bin/emake \
#   --emake-cm=sdit-ec1.dal.design.ti.com \
#   --emake-class=Android-Ubuntu --emake-maxagents=30 --emake-build-label=Linux_27.x_DailyBuild_10 \
#   --emake-root=/home/axel/arm-2008q3/bin:/home/axel/p-android/3630zoom29 uImage

make ARCH=arm CROSS_COMPILE=~/arm-2008q3/bin/arm-none-linux-gnueabi- uImage 2>&1|tee build_log.txt
fi


#if there is no kernel, build failed, exit
if [ ! -f ~/p-android/$BUILD/arch/arm/boot/uImage ]; then
	echo "KERNEL BUILD FAILED!!"
	echo "exiting make2"
	exit
fi

###############################################################################
#	MAKE THE MODULES
###############################################################################

if [ $MODULES == "ON" ];then
	echo "***************"
	echo "MAKING MODULES"
	echo "***************"
	find . -name "*.ko" -exec rm {} \;
	make ARCH=arm CROSS_COMPILE=~/arm-2008q3/bin/arm-none-linux-gnueabi- modules

fi


###############################################################################
#	make the package
###############################################################################

echo "***************"
echo "MAKING PACKAGE"
echo "***************"

if [ ! -d "builds" ]; then
	mkdir ./builds
fi


# create pkg dir with current date.
DATE=`date +%Y.%m.%d.%H.%M.%S`
DATE=$DATE.$BUILD-$DESC
mkdir ./builds/$DATE

#find all modules and copy them to pkg
if [ $MODULES == "ON" ];then
	#find . -name "*.ko" -exec cp -v {} ./builds/$DATE \;
#	 find . -name "*.ko"|grep -v builds|exec cp 
	cp ./drivers/usb/host/ehci-hcd.ko ./builds/$DATE
	cp ./drivers/usb/host/ohci-hcd.ko ./builds/$DATE
fi

# copy some usefull info on the changes.txt.			
echo $CONFIG				>  ./builds/$DATE/changes.txt
echo $PWD	 				>> ./builds/$DATE/changes.txt
echo "COMMIT:"				>> ./builds/$DATE/changes.txt
git log --pretty=oneline -10 >> ./builds/$DATE/changes.txt
echo "***********************">>./builds/$DATE/changes.txt
echo " THE COMMITS"
echo "***********************">>./builds/$DATE/changes.txt
git diff HEAD^10 HEAD >>./builds/$DATE/changes.txt
#The Patch that created this build. from the last commit.
git diff 					> ./builds/$DATE/diff.patch

#the kernel
cp -v ./arch/arm/boot/uImage	./builds/$DATE/uImage

#the log
cp -v build_log.txt ./builds/$DATE/

# the config used.
cp -v ./.config ./builds/$DATE/config


###############################################################################
#	SET UP THE LINK
###############################################################################
echo "******************************"
echo "		INSTALLING				"
echo "******************************"

#setup global link
rm ~/bin/uImage 
cp ~/p-android/$BUILD/builds/$DATE/uImage ~/bin/uImage

#set-up fs
#rm /home/axel/export/fslink
#ln -s $FS_LINK /home/axel/export/fslink

#set the correct inittab for console.
if [ $FILE_SYSTEM == "busybox" ];then
	rm /home/axel/TUNNEL/export/fslink/etc/inittab
	ln -s ./$INITTAB /home/axel/export/fslink/etc/inittab
fi

#copy the modules to nfs file-sytem
if [ $MODULES == "ON" ];then
cp -rfv ./builds/$DATE/*.ko /home/axel/export/fslink
fi
###############################################################################
#	END
###############################################################################
time2=`date`

echo "***************"
echo " DONE "
echo "***************"
echo $DATE 
echo "DONE!"
echo "STATED= "$time1
echo "ENDED= "$time2


