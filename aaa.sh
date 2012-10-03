# force to be root
sudo echo ""

MANIFEST_URL=http://jfumgbuild-depot.jf.intel.com/build/eng-builds/main/PSI/weekly/latest/manifest-generated.xml
MANIFEST_FILE=manifest-generated.xml

MANIFEST_URL=http://jfumgbuild-depot.jf.intel.com/build/eng-builds/r3/PSI/weekly/latest/manifest-generated.xml
MANIFEST_FILE=manifest-generated.xml

#PROJECT_DIR=/home/axelh/GITS/MAIN
#PROJECT_DIR=/home/axelh/GITS/R3STABLE
#PROJECT_DIR=/home/axelh/GITS/INTEL_BRCM
PROJECT_DIR=/home/axelh/GITS/BRCM
#PROJECT_DIR=/home/axelh/GITS/MAIN2

PLATFORM=mfld_pr2
OUT=out/target/product/$PLATFORM
MY_KERNEL=$PROJECT_DIR/$OUT/axel_kernel
MY_BOOT_DIR=$PROJECT_DIR/$OUT/axel_boot
MY_RAMDISK=$PROJECT_DIR/$OUT/axel_ramdisk


#BUILD_TYPE=userdebug
BUILD_TYPE=eng

BRCM_MODULE=$PROJECT_DIR/hardware/broadcom/PRIVATE/wlan/bcm43xx/open-src/src/dhd/linux/dhd-cdc-sdmmc-android-panda-icsmr1-cfg80211-oob-3.0.34/bcmdhd.ko
CUR_DIR=$PWD

ARG1=$1
ARG2=$2
ARG3=$3
ARG4=$4
ARG5=$5


###############################################################################
# HELPERS 
###############################################################################

print()
{
	echo "#######################################################"
	echo $1
	echo "#######################################################"
}

exit_if_no_file()
{
	if [ ! -e $1 ]; then
		print "$1 does not exists. Abort"
		exit 1;
	fi
}

exit_if_file()
{
	if [ -e $1 ]; then
		print "$1 exists. Abort PLEASE REMOVE rm -rf $1"
		exit 1;
	fi
}

check()
{
	SS=`df -h|grep sda3|awk '{printf $4}'|awk 'BEGIN{FS="G"}{printf $1}'`
	echo "$SS"

}

goto_project()
{
	cd $PROJECT_DIR
}

init()
{
	print "project: $PROJECT_DIR"
	cd $PROJECT_DIR
	rm $HOME/project
	rm $PROJECT_DIR/kernel
	rm $PROJECT_DIR/outp

	ln -s $PROJECT_DIR $HOME/project
	ln -s $PROJECT_DIR/hardware/intel/linux-2.6 $PROJECT_DIR/kernel
	ln -s $PROJECT_DIR/$OUT $PROJECT_DIR/outp
}

###############################################################################
# INIT FROM MAINIFEST
###############################################################################
sync_new_project()
{
	exit_if_file $PROJECT_DIR 

	mkdir $PROJECT_DIR
	cd $PROJECT_DIR

	print "REPO INIT $MANIFEST_FILE"
	repo init -u git://android.intel.com/manifest -b platform/android/main -m android-main

	print "SETTING MAINFEST $MANIFEST_FILE"
	wget $MANIFEST_URL
	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST_FILE
	cp  $MANIFEST_FILE ./.repo/manifests
	repo init -m  $MANIFEST_FILE

	print "REPO SYNC"
	repo sync

	#Check that sync worked and try again if not.
	if [ ! -e $PROJECT_DIR/frameworks ]; then
		print "REPO SYNC FAILED, TRYING AGAIN"
		rm -rf $PROJECT_DIR
		new_project;
	fi

	print "BUILDING SYSTEM"
	source build/envsetup.sh
	lunch $PLATFORM-$BUILD_TYPE
	make -j8 $PLATFORM
	make -j8 flashfiles
	make -j8 blank_flashfiles	
	
}

sync_repo()
{	
	print "SYNC_REPO $1"
	cd $1
	repo forall -c "git pull"
	repo sync
	source build/envsetup.sh
	lunch $PLATFORM-$BUILD_TYPE
	make -j8 $PLATFORM
	make flashfiles

}

sync_all()
{
	sync_repo /home/axelh/GITS/MAIN
	sync_repo /home/axelh/GITS/R3STABLE
	sync_repo /home/axelh/GITS/BRCM
}

###############################################################################
# MAKERS
###############################################################################
make_kernel()
{
	cd $PROJECT_DIR 
	KFLAGS="ARCH=x86 CROSS_COMPILER=/home/axelh/GITS/toolchain/i686-android-linux-4.4.3/bin/i686-android-linux- -j8 O=$MY_KERNEL"

	if [ ! -e $MY_KERNEL ]; then
		mkdir $MY_KERNEL
		echo "ddd"
		echo $PROJECT_DIR
		echo $OUT
		cp $PROJECT_DIR/$OUT/kernel_build/.config $MY_KERNEL
	fi		

	if [ ! -e $MY_KERNEL/.config ]; then
		cp $PROJECT_DIR/$OUT/kernel_build/.config $MY_KERNEL/
	fi
	
	cd $PROJECT_DIR
	source build/envsetup.sh
	lunch $PLATFORM-$BUILD_TYPE
	cd $PROJECT_DIR/hardware/intel/linux-2.6

	print "BUILD KERNEL"
	rm $MY_KERNEL/arch/x86/boot/bzImage
	make $KFLAGS bzImage	
	if [ ! -e $MY_KERNEL/arch/x86/boot/bzImage ]; then
		print "KERNEL BUILD ERROR"
		exit
	fi

	if [ ! -e $MY_BOOT_DIR ]; then
		mkdir $MY_BOOT_DIR
	fi
	cp $MY_KERNEL/arch/x86/boot/bzImage $MY_BOOT_DIR

	make $KFLAGS modules
#	rm -rf $MY_RAMDISK/lib/modules/*

	echo copy
	find  $MY_KERNEL -iname "*.ko" -exec cp -rf "{}" $MY_RAMDISK/lib/modules \;


	cd $MY_RAMDISK/lib/modules
	find . -type f -name '*.ko' | xargs -n 1 ~/GITS/toolchain/i686-android-linux-4.4.3/bin/i686-android-linux-objcopy --strip-unneeded

}

make_wireless()
{
	cd $PROJECT_DIR
	vendor/intel/support/wl12xx-compat-build.sh -c mfld_pr2
	
	find $PROJECT_DIR/$OUT/compat_modules/lib/modules -iname "*.ko" -exec cp -rf "{}" $MY_RAMDISK/lib/modules \;
	make_ramdisk;
}

make_ramdisk()
{
	print "make_ramdisk"
	if [ ! -e $MY_BOOT_DIR ]; then
		mkdir $MY_BOOT_DIR
	fi

	if [ ! -e $MY_RAMDISK ]; then
		mkdir $MY_RAMDISK
		cd $MY_RAMDISK
		gunzip -c ../ramdisk.img | cpio -i
	fi

	cp $BRCM_MODULE $MY_RAMDISK/lib/modules
	cp $PROJECT_DIR/$OUT/target/product/mfld_pr2/root/init $MY_RAMDISK/init

	cd $MY_RAMDISK
	find . | cpio -o -H newc | gzip > $MY_BOOT_DIR/my_ramdisk.img
	make_bootimage;	
}

make_bootimage()
{
	print "make_bootimage"
	cd $PROJECT_DIR

	exit_if_no_file $MY_BOOT_DIR/my_ramdisk.img
	exit_if_no_file $MY_BOOT_DIR/bzImage
	rm $MY_BOOT_DIR/boot.bin

	source build/envsetup.sh
#--cmdline "init=/init pci=noearly console=ttyS0 console=logk0 earlyprintk=nologger loglevel=8 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on idle=poll" \

#init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 emmc_ipanic.ipanic_part_number=6


	vendor/intel/support/mkbootimg \
--cmdline "init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 emmc_ipanic.ipanic_part_number=6" \
--ramdisk $MY_BOOT_DIR/my_ramdisk.img \
--kernel $MY_BOOT_DIR/bzImage \
--output $OUT/axel_boot/boot.bin \
--product $PLATFORM --type mos

}

make_broadcom()
{
	cd $PROJECT_DIR
	rm $BRCM_MODULE
	rm $MY_RAMDISK/lib/modules/bcmdhd.ko

	$PROJECT_DIR/vendor/intel/support/bcmdhd-build.sh mfld_pr2
	exit_if_no_file $BRCM_MODULE

	cp $BRCM_MODULE $MY_RAMDISK/lib/modules
	exit_if_no_file $MY_RAMDISK/lib/modules

	make_ramdisk;
	make_bootimage;
}

make_flash_files()
{
	cd $PROJECT_DIR
	source build/envsetup.sh
	lunch $PLATFORM-$BUILD_TYPE
	make -j8 $PLATFORM 
	make -j8 flashfiles
	make -j8 blank_flashfiles
}




###############################################################################
# FLASHERS
###############################################################################

flash_my_boot()
{
	exit_if_no_file $MY_BOOT_DIR/boot.bin
	adb reboot bootloader
#	adb reboot recovery
	fastboot flash boot $MY_BOOT_DIR/boot.bin
	fastboot continue
}

flash_this()
{

	cd $CUR_DIR
#	adb reboot recovery
	adb reboot bootloader
	fastboot erase data;
	fastboot erase system;
	fastboot erase boot;
	fastboot flash boot boot.bin ;
	if [ -e system.tar.gz ]; then
		fastboot flash system system.tar.gz ;
	else
		fastboot flash system system.img.gz 
	fi
	fastboot continue


}


flash_my_build()
{
	exit_if_no_file $MY_BOOT_DIR/boot.bin
	exit_if_no_file $PROJECT_DIR/$OUT/system.tar.gz

#	adb reboot recovery
	adb reboot bootloader
	fastboot erase system
	fastboot erase data
	fastboot erase boot
	fastboot flash boot $MY_BOOT_DIR/boot.bin
	fastboot flash system $PROJECT_DIR/$OUT/system.tar.gz
	fastboot continue
}



###############################################################################
# POWER
###############################################################################
power_on(){
phy 5 on
}
power_off(){
phy 5 off
}
power_restart(){
power_off;sleep 2;power_on
}
usb_on(){
phy 4 on
}
usb_off(){
phy 4 off
}


###############################################################################
# RUNNERS
###############################################################################
run_syncer()
{
	

	while true; do
		cd $CUR_DIR
		repo sync
		lunch $PLATFORM-eng
	        make -j8 $PLATFORM
		NOW=$(date +%s)
		TARGET=$(date -d '01/01/2012 12:00' +%s)
		SEC=$(( $TARGET - $NOW ))
		sleep $SEC
	done
		
}




usage()
{
echo "
USAGE IS:
	sn)	sync_new_project;break;;
	sa)	sync_all;break;;

	mk)	make_kernel;break;;
	mb)	make_bootimage;break;;
	mq)	make_broadcom;break;;
	mr)	make_ramdisk;break;;
	mw)	make_wireless;break;;
	mf)	make_flash_files;break;;

	fb)	flash_my_boot;break;;
	ff)	flash_my_build;break;;
	ft)	flash_this;break;;

	pon)	power_on;break;;
	poff)	power_off;break;;
	prst)	power_restart;break;;
	uon)	usb_on;break;;
	uoff)	usb_off;break;;
	cd)	goto_project;break;;
	
	rs)	run_syncer;break;;

	c)	check;break;;
	e)	vim ~/tools/aaa.sh;break;;
	*)	usage;break;;
"
}
###############################################################################
# MAIN
###############################################################################
if [ -z "$1" ]; then
        usage
        exit
fi

#local init function 
init;

while [ ! -z "$1" ]; do
	case $1 in
	sn)	sync_new_project;break;;
	sa)	sync_all;break;;

	mk)	make_kernel;break;;
	mb)	make_bootimage;break;;
	mq)	make_broadcom;break;;
	mr)	make_ramdisk;break;;
	mw)	make_wireless;break;;
	mf)	make_flash_files;break;;

	fb)	flash_my_boot;break;;
	ff)	flash_my_build;break;;
	ft)	flash_this;break;;

	pon)	power_on;break;;
	poff)	power_off;break;;
	prst)	power_restart;break;;
	uon)	usb_on;break;;
	uoff)	usb_off;break;;
	cd)	goto_project;break;;
	
	rs)	run_syncer;break;;

	c)	check;break;;
	e)	vim ~/tools/aaa.sh;break;;
	*)	usage;break;;
	esac
	shift
done


echo "done"








