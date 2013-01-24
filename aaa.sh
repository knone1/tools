# force to be root
sudo echo ""

MANIFEST_URL=http://jfumgbuild-depot.jf.intel.com/build/eng-builds/main/PSI/weekly/latest/manifest-generated.xml
MANIFEST_FILE=manifest-generated.xml

#MANIFEST_URL=http://jfumgbuild-depot.jf.intel.com/build/eng-builds/r3/PSI/weekly/latest/manifest-generated.xml
#MANIFEST_FILE=manifest-generated.xml


PROJECT_DIR=/home/axelh/GITS/MAIN3

#PLATFORM=mfld_pr2
#PLATFORM=merr_vv
#PLATFORM=victoriabay
PLATFORM=blackbay

OUT=out/target/product/$PLATFORM
MY_KERNEL=$PROJECT_DIR/$OUT/axel_build
MY_BOOT_DIR=$PROJECT_DIR/$OUT/axel_boot
MY_RAMDISK=$PROJECT_DIR/$OUT/axel_ramdisk

BRANCH=main
#BRANCH=r3-stable

#BUILD_TYPE=userdebug
#BUILD_TYPE=eng
BUILD_TYPE=mfld_pr2_bcm
#BUILD_TYPE=victoriabay

#BRCM_MODULE=$PROJECT_DIR/hardware/broadcom/PRIVATE/wlan/bcm4335/open-src/src/dhd/linux/dhd-cdc-sdmmc-android-intel-icsmr1-cfg80211-oob-3.0.34/bcmdhd.ko
#BRCM_MODULE=/home/axelh/GITS/BRCM/hardware/broadcom/PRIVATE/wlan/bcm43xx/open-src/src/dhd/linux/dhd-cdc-sdmmc-android-panda-icsmr1-cfg80211-oob-3.0.34/bcmdhd.ko

#BRCM_MODULE=$PROJECT_DIR/hardware/broadcom/wlan_driver/bcm4335/open-src/src/dhd/linux/dhd-cdc-sdmmc-android-intel-jellybean-cfg80211-oob-3.0.34/bcmdhd.ko
BRCM_MODULE=$PROJECT_DIR/hardware/broadcom/wlan_driver/bcm4334/open-src/src/dhd/linux/dhd-cdc-sdmmc-android-intel-jellybean-cfg80211-oob-3.0.34/bcmdhd.ko



# 2035  adb push ./out/target/product/mfld_pr2/system/etc/wifi/bcmdhd_4334.cal /system/etc/wifi/bcmdhd_4334.cal
# 2036  adb push ./out/target/product/mfld_pr2/system/etc/firmware/fw_bcmdhd_4334.bin /system/etc/firmware



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
	ln -s $PROJECT_DIR/hardware/broadcom/wlan_driver/bcm4334 bcm4334
	ln -s $PROJECT_DIR/hardware/broadcom/wlan_driver/bcm4335 bcm4335

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


#	print "SETTING MAINFEST $MANIFEST_FILE"
#	wget $MANIFEST_URL
#	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST_FILE
#	cp  $MANIFEST_FILE ./.repo/manifests
#	repo init -m  $MANIFEST_FILE

	print "REPO SYNC"
	repo sync -j4
	repo start topic1
#	repo forall -c "git checkout --track -b main remotes/umg/platform/android/main"

	#Check that sync worked and try again if not.
#	if [ ! -e $PROJECT_DIR/frameworks ]; then
#		print "REPO SYNC FAILED, TRYING AGAIN"
#		rm -rf $PROJECT_DIR
#		sync_new_project
#	fi

	print "BUILDING SYSTEM"
	source build/envsetup.sh
	lunch mfld_pr2_bcm-eng
	
	make -j8 mfld_pr2_bcm
	make -j8 flashfiles
	make -j8 blank_flashfiles	
	
}

repo_reset()
{
	repo forall -c "git checkout -b temp1"
	repo forall -c "git checkout temp1"
	repo forall -c "git branch -D main"
	repo forall -c "git checkout --track -b main remotes/umg/platform/android/main"
	repo forall -c "git pull"
}


sss()
{
	
	getPatch.sh -apply 72703 72702 72235
	make -j8 $BUILD_TYPE
	make flashfiles
	make blank_flashfiles
	rm -rf ./72703_72702_72235
	mv  ./pub ./72703_72702_72235


	getPatch.sh -apply 77503
	make -j8 $BUILD_TYPE
	make flashfiles
	make blank_flashfiles
	rm -rf ./72703_72702_72235_78157_78158_78159_78160_78161_77503
	mv  ./pub ./72703_72702_72235_78157_78158_78159_78160_78161_77503


	getPatch.sh -apply 77503 78162 78163 78164 78165 78166 78314 
	getPatch.sh -status >./status.txt
	make -j8 $BUILD_TYPE
	make flashfiles
	make blank_flashfiles
	rm -rf ./77503_78162_78163_78164_78165_78166_78314
	mv  ./pub ./77503_78162_78163_78164_78165_78166_78314
	mv ./status.txt ./77503_78162_78163_78164_78165_78166_78314


}
sync_repo()
{	
	print "SYNC_REPO $1"
	cd $PROJECT_DIR
#	repo_reset

	source build/envsetup.sh

	lunch victoriabay-eng
	make -j8 victoriabay
	make flashfiles
	make blank_flashfiles
	mv ./pub ./out
	mv ./out ./victoriabay.out

	lunch mfld_pr2_bcm-eng
#	getPatch.sh -apply 78157 78158 78159 78160 78161 78316
#	getPatch.sh -status >./status.txt
	make -j8 mfld_pr2_bcm
	make flashfiles
	make blank_flashfiles
	mv ./pub ./out
	mv ./out ./mfld_pr2_bcm.out
	


}

sync_all()
{
	PROJECT_DIR=/home/axelh/GITS/MAIN2
	REMOTE_BRANCH=remotes/umg/platform/android/main
	BRANCH=main
	sync_repo

	PROJECT_DIR=/home/axelh/GITS/R3STABLE
	REMOTE_BRANCH=remotes/umg/platform/android/r3-stable
	BRANCH=r3-stable
	sync_repo
}

###############################################################################
# MAKERS
###############################################################################
make_kernel()
{
	cd $PROJECT_DIR 

	rm $MY_KERNEL/arch/x86/boot/bzImage	
	rm $MY_BOOT_DIR/bzImage

#	sed -i 's/_preserve_kernel_config=""/_preserve_kernel_config="yes"/g' ./vendor/intel/support/kernel-build.sh
#	sed -i 's/\/kernel_build/\/axel_kernel/g' ./vendor/intel/support/kernel-build.sh
	export TARGET_BOARD_PLATFORM=medfield
	export TARGET_DEVICE=blackbay
	export STRIP_MODE=1
	vendor/intel/support/kernel-build.sh -v  -j 8
	cp $PROJECT_DIR/$OUT/root/lib/modules/* $MY_RAMDISK/lib/modules/
	cd $MY_RAMDISK/lib/modules
	find . -type f -name '*.ko' | xargs -n 1 ~/GITS/toolchain/i686-android-linux-4.4.3/bin/i686-android-linux-objcopy --strip-unneeded


#	cd  vendor/intel/support;git checkout kernel-build.sh
	exit_if_no_file $MY_KERNEL/arch/x86/boot/bzImage

	cp $MY_KERNEL/arch/x86/boot/bzImage $MY_BOOT_DIR/bzImage
	
}

make_wireless()
{
	cd $PROJECT_DIR
#	cp ~/tools/wl12xx-compat-build-axel2.sh vendor/intel/support/wl12xx-compat-build-axel2.sh
	vendor/intel/support/wl12xx-compat-build.sh -c mfld_pr2
	cd $PROJECT_DIR/hardware/ti/wlan
	find . -iname "*.ko" -exec cp -rf "{}" $MY_RAMDISK/lib/modules \;
	
	cd $MY_RAMDISK/lib/modules
	find . -type f -name '*.ko' | xargs -n 1 ~/GITS/toolchain/i686-android-linux-4.4.3/bin/i686-android-linux-objcopy --strip-unneeded
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

#	cp $BRCM_MODULE $MY_RAMDISK/lib/modules
#	cp $PROJECT_DIR/$OUT/target/product/mfld_pr2/root/init $MY_RAMDISK/init

	cd $MY_RAMDISK
	find . | cpio -o -H newc | gzip > $MY_BOOT_DIR/my_ramdisk.img
	make_bootimage;	
}

make_bootimage()
{
	print "make_bootimage"
	cd $PROJECT_DIR

	exit_if_no_file $MY_BOOT_DIR/my_ramdisk.img

#	cp $OUT/kernel_build/arch/x86/boot/bzImage $MY_BOOT_DIR/bzImage
	cp $MY_KERNEL/arch/x86/boot/bzImage $MY_BOOT_DIR/bzImage

	exit_if_no_file $MY_BOOT_DIR/bzImage
	rm $MY_BOOT_DIR/boot.bin

	source build/envsetup.sh
#--cmdline "init=/init pci=noearly console=ttyS0 console=logk0 earlyprintk=nologger loglevel=8 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on idle=poll" \

#init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 emmc_ipanic.ipanic_part_number=6

#init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 emmc_ipanic.ipanic_part_number=6 androidboot.wakesrc=0B androidboot.mode=main androidboot.wakesrc=0B androidboot.mode=main ignore_bt_lpm androidboot.wakesrc=0B androidboot.mode=main
#nit=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=blackbay emmc_ipanic.ipanic_part_number=1 androidboot.wakesrc=0B androidboot.mode=main



	vendor/intel/support/mkbootimg \
--cmdline "init=/init pci=noearly console=ttyS0 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 emmc_ipanic.ipanic_part_number=6 androidboot.wakesrc=0B androidboot.mode=main androidboot.wakesrc=0B androidboot.mode=main ignore_bt_lpm androidboot.wakesrc=0B androidboot.mode=main" \
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

	$PROJECT_DIR/vendor/intel/support/bcmdhd-build.sh $PLATFORM bcm4334
	exit_if_no_file $BRCM_MODULE
	exit_if_no_file $MY_RAMDISK/lib/modules

	cp $BRCM_MODULE $MY_RAMDISK/lib/modules
	make_ramdisk;
	make_bootimage;


#	cd ~/GITS/BRCM/brcm/firmware/4334b1min-roml
#	cd ~/GITS/BRCM_MAIN/hardware/broadcom/PRIVATE/wlan/bcm4334/firmware/4334b1min-roml/
#	cd ~/GITS/BRCM_MAIN/hardware/broadcom/PRIVATE/wlan/bcm4334/firmware/4335a0min-roml/
	echo "push BRCM FW..."
#	adb root
#	adb remount
#	adb push $PROJECT_DIR/device/intel/fw/wifi_bcm/bcm4335/fw_bcmdhd_4335.bin  /system/etc/firmware/fw_bcmdhd_4334.bin
#	adb push $PROJECT_DIR/device/intel/fw/wifi_bcm/bcm4335/bcm94335wlagb.txt /system/etc/wifi/bcmdhd_4334.cal


}

make_flash_files()
{
	cd $PROJECT_DIR
	source build/envsetup.sh
	lunch $BUILD_TYPE-eng
	make -j8 $BUILD_TYPE cd cd 
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
	sr)	sync_repo;break;;

	mk)	make_kernel;break;;
	mb)	make_bootimage;break;;
	mq)	make_broadcom;break;;
	mr)	make_ramdisk;break;;
	mw)	make_wireless;break;;
	mf)	make_flash_files;break;;

	fb)	flash_my_boot;break;;
	ff)	flash_my_build;break;;
	ft)	flash_this;break;;


	rr)	repo_reset;break;;

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








