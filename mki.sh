http_proxy=

DIR=~/r3

# R3 INFO #
R3_DIR=~/r3
R3_RELEASE=2012_WW15
R3_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r3/android/ice-cream-sandwich-platform/releases
R3_MANIFEST=$R3_URL/$R3_RELEASE/manifest-$R3_RELEASE-generated.xml

# R2 INFO #
R2_DIR=~/r2
R2_RELEASE=2012_WW14
R2_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r2/android/gingerbread-platform/releases
R2_MANIFEST=$R2_URL/$R2_RELEASE/manifest-$R2_RELEASE-generated.xml

# R3 INFO #
CV_DIR=~/r3
CV_RELEASE=2012_WW15
CV_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r3/android/ice-cream-sandwich-platform/releases
CV_MANIFEST=$CV_URL/$CV_RELEASE/manifest-$CV_RELEASE-generated.xml


PLATFORM=ctp_pr0
PLATFORM=mfld_pr2
OUT=out/target/product
OUT_PLATFORM=$OUT/$PLATFORM

rm -rf $R2_DIR
rm -rf $R3_DIR

ln -s ~/RELEASES/R3/$R3_RELEASE ~/r3
ln -s ~/RELEASES/R2/$R2_RELEASE ~/r2


#START A FULL BUIL
print(){
	echo "#######################################################"
	echo $1
	echo "#######################################################"
}

set_dir()
{
	if [ "$1" = "r3" ]; then
		DIR=$R3_DIR
	elif [  "$1" = "r2" ]; then
		DIR=$R2_DIR
	elif [  "$1" = "cv" ]; then
		DIR=$R3_DIR
	else
		DIR=$R3_DIR
	fi
}

full_andrid_build(){
	set_dir $1
	cd $DIR
	
	case $1 in 
	r2)	
		PLATFORM=mfld_pr2
		;;
	r3)	
		PLATFORM=mfld_pr2
		;;
	cv)     
		PLATFORM=ctp_pr0
		;;
	*)exit 1;;
	esac
        source build/envsetup.sh
        lunch $PLATFORM-eng
	vendor/intel/support/build_all.sh -c $PLATFORM
}

build_boottarball(){
	set_dir $1
	cd $DIR
	rm -rf $DIR/$OUT_PLATFORM/boot.bin
	rm -rf $DIR/$OUT_PLATFORM/kernel_build/arch/x86/boot/bzImage
	rm -rf $DIR/$OUT_PLATFORM/kernel_build/arch/i386/boot/bzImage
	rm -rf $DIR/$OUT_PLATFORM/bzImage
	source build/envsetup.sh
	lunch $PLATFORM-eng
	make -j4 boottarball	
}

incremental_kernel(){
	set_dir $1
	print "BUILDING KERNEL FOR: $1 PLATFORM: $PLATFORM"

	cd $DIR
	rm -rf $DIR/$OUT_PLATFORM/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT_PLATFORM/boot/kernel
	$DIR/vendor/intel/support/kernel-build.sh -c $PLATFORM -o $DIR/$OUT_PLATFORM/kernel_build
	if [ ! -e $DIR/$OUT_PLATFORM/kernel_build/arch/x86/boot/bzImage ]; then
		print "######  BUILD ERROR #####"
	exit
	fi
	CTP_CMDLINE="init=/init pci=noearly console=ttyS0 earlyprintk=mrst loglevel=8 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=ctp_pr0 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on"
	MFLD_CMDLINE="init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=8 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on apic=debug"
	
	vendor/intel/support/mkbootimg --cmdline $MFLD_CMDLINE  --ramdisk $OUT_PLATFORM/boot/ramdisk.img \
	--kernel $OUT_PLATFORM/kernel_build/arch/i386/boot/bzImage \
	--output $OUT_PLATFORM/boot.bin \
	--product $PLATFORM \
	--type mos
	
}

build_kernel()
{
	reboot
	print "BUILDING $1"
	case $1 in
	r2)incremental_kernel $1;;
	r3)incremental_kernel $1;;
	cv)incremental_kernel $1;;
	boottarball_r3)build_boottarball $1;;
	boottarball_r2)build_boottarball $1;;
	boottarball_cv)build_boottarball $1;;
	*) print "build_kernel: error!"
	esac
}

reboot(){
	print "REBOOT"
	adb shell "update_osip --backup --invalidate 0; update_osip --backup --invalidate 1;reboot"
#	adb reboot-bootloader
}

flash_kernel()
{
	reboot
	set_dir $1
	cd $DIR
	print "FLASH"
	sudo fastboot flash boot $DIR/$OUT/$PLATFORM/boot.bin
	sudo fastboot continue
}

#GET DAILY BUILD AND FLASHIT
get(){

	export http_proxy=

	case $1 in 
	r2)

		THIS_RELEASE=$R2_RELEASE
		THIS_URL=$R2_URL
		THIS_DIR=~/DB/R2/$R2_RELEASE
		PLAT_DIR=MFLD_PRx
		FILE_NAME="*fastboot*.zip"
		;;
	r3)
		THIS_RELEASE=$R3_RELEASE
		THIS_URL=$R3_URL
		THIS_DIR=~/DB/R3/$R3_RELEASE
		PLAT_DIR=MFLD_PRx
		FILE_NAME="*fastboot*.zip"
		;;
	cv)
		THIS_RELEASE=$CV_RELEASE
		THIS_URL=$CV_URL
		THIS_DIR=~/DB/CV/$CV_RELEASE
		PLAT_DIR=CTP_PR0
		FILE_NAME="ctp_vv-VV-build-eng-system.zip"
		;;
	
	esac
	
	if [ -e $THIS_DIR ]; then
		echo "$THIS_DIR exists."
		exit 1;
	fi
	mkdir -p $THIS_DIR
	cd $THIS_DIR
	print "get system file."
	wget -r -l1 --no-parent -A$FILE_NAME  http://$THIS_URL/$THIS_RELEASE/$PLAT_DIR/flash_files/build-eng/
	mv $THIS_URL/$THIS_RELEASE/$PLAT_DIR/flash_files/build-eng/* .
	rm -rf jfumgbuild-depot.jf.intel.com
	print "get PR3.1 blankphone."
	wget -r -l1 --no-parent -A"*blankphone.zip" http://$THIS_URL/$THIS_RELEASE/$PLAT_DIR/flash_files/blankphone/
	mv $THIS_URL/$THIS_RELEASE/$PLAT_DIR/flash_files/blankphone/* .
	rm -rf jfumgbuild-depot.jf.intel.com

}

build_all(){
	
#	print "BUILD ctp_pr0-eng"
#	vendor/intel/support/build_all.sh -c ctp_pr0
#	mv ./out ./out_ctp_pr0

	print "BUILD mfld_pr2"
        vendor/intel/support/build_all.sh -c mfld_pr2
	mv ./out ./out_mfld_pr2	

}

#SYNC REPO TO A RELEASE
sync(){
	set_dir $1
	cd $DIR
	case $1 in 
	r2) 	wget http://$R2_URL/$R2_RELEASE/manifest-$R2_RELEASE-generated.xml
		RELEASE=$R2_RELEASE 
		;;
	r3)	 wget	http://$R3_URL/$R3_RELEASE/manifest-$R3_RELEASE-generated.xml
		RELEASE=$R3_RELEASE
		;;
	*)exit 1;;
	esac
	print "sync $1 to $RELEASE"

	cp ./manifest-$RELEASE-generated.xml ./.repo/manifests
	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./.repo/manifests//manifest-$RELEASE-generated.xml
	cd $DIR
	repo init -m manifest-$RELEASE-generated.xml 
	repo sync -d

	build_all
}

scratch()
{
	print "SCRATCH $1"

	case $1 in 
	r2)	NEW_BUILD_DIR=~/RELEASES/R2/$R2_RELEASE 	
		RELEASE=$R2_RELEASE
		MANIFEST=$R2_MANIFEST
		;;
	r3)	NEW_BUILD_DIR=~/RELEASES/R3/$R3_RELEASE
		RELEASE=$R3_RELEASE
		MANIFEST=$R3_MANIFEST
		if [ -ne ~/RELEASES/R3 ];then
			mkdir -p ~/RELEASES/R3
		fi
		;;
	cv)     NEW_BUILD_DIR=~/RELEASES/R3/$CV_RELEASE
		RELEASE=$CV_RELEASE
		MANIFEST=$CV_MANIFEST
		;;
	*)exit 1;;
	esac

	if [ "$2" = "-f" ] ; then
		rm -rf $NEW_BUILD_DIR
	fi

	if [ -e $NEW_BUILD_DIR ]; then
		print "$RELEASE BUILD EXISTS PLEASE REMOVE IT. or use -f"
		exit
	fi

        mkdir -p $NEW_BUILD_DIR
        cd $NEW_BUILD_DIR

	print "REPO INIT"
	repo init -u git://android.intel.com/manifest -b platform/android/main -m android-main
	
	print "GET MANIFEST"
        wget $MANIFEST
        MANIFEST=`ls *.xml`
        sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST

	
        cp  $MANIFEST ./.repo/manifests
	print "REPO INIT MANIFEST:"
        repo init -m  $MANIFEST

	print "REPO SYNC"
        repo sync

	build_all
}


usage(){
echo "usage is:

-k) build_kernel: (mki.sh -k boottarball_r3 || mki.sh -k r3)
-f) flash_kernel: (mki.sh -fk r3)
-g) get code and build: (mki.sh -g)
-b) runs make at top dir: mki.sh -f r3
-d) Download prebuilt binaries. mki.sh -d r3
-p) make r3 package from local build
"
}
make_package()
{
	set_dir $1
	cd $DIR
	case $1 in
	r2)	RELEASE=$R2_RELEASE
		DB_DIR_FILES=~/DB/R2/$RELEASE/mfld_prx-eng-fastboot*
		DB_DIR=~/DB/R2
		OUT_DIR=$OUT_PLATFORM
		;;
	r3)	RELEASE=$R3_RELEASE
		DB_DIR_FILES=~/DB/R3/$RELEASE/mfld_prx-eng-fastboot*
		DB_DIR=~/DB/R3
		OUT_DIR=$OUT_PLATFORM
		;;
	cv)	RELEASE=$CV_RELEASE
		DB_DIR_FILES=~/DB/CV/$RELEASE/ctp_vv-VV-build-eng-system*
		DB_DIR=~/DB/CV
		OUT_DIR=out/target/product/ctp_pr0
		;;
	*)exit 1;;
	esac
	if [ ! -e $DB_DIR/$RELEASE ]; then
		print "error $DB_DIR/$RELEASE does not exit."
		exit 1;
	fi
	cd $OUT_DIR
	rm -rf my_pkg
	mkdir my_pkg
	cd my_pkg
	cp ../boot.bin ./
	cp ../system.tar.gz ./
	cp ../radio_firmware.bin ./
	cp ../recovery.img ./
	cp $DB_DIR_FILES/IFWI* ./
	cp $DB_DIR_FILES/SIGNED* ./
	cp $DB_DIR_FILES/flash.xml ./
	cp $DB_DIR_FILES/kboot.bin ./
	rm my_$1_build.zip
	zip my_$1_build.zip *
	rm -rf $DB_DIR/MY_BUILD
	mkdir $DB_DIR/MY_BUILD
	cp my_$1_build.zip $DB_DIR/MY_BUILD
}

make_shit(){
	cd $R3_DIR
	source build/envsetup.sh
	lunch mfld_pr2-eng
	cd ~/r3/hardware/intel/PRIVATE/platform_test/RtcPingDownloadTester/src/com/intel	
#	cp ~/BOX/IN/*.java ./
	rm -rf  $R3_DIR/out/target/product/mfld_pr2/system/app/RtcPingDownloadTester.apk
	mm
	cd $R3_DIR
	adb uninstall com.intel
	adb install  $R3_DIR/out/target/product/mfld_pr2/system/app/RtcPingDownloadTester.apk
	

}
make_shit2(){
	cd $R3_DIR
	source build/envsetup.sh
	lunch mfld_pr2-eng
	cd frameworks/base/services/java/com/android/server
	mm
	cd $R3_DIR/frameworks/base/services/jni
	mm
	cd $R3_DIR
	adb root
	adb remount
#	adb push out/target/product/mfld_pr2/system/lib/libandroid_servers.so /system/lib/libandroid_servers.so
	adb push out/target/product/mfld_pr2/system/framework/services.jar /system/framework/services.jar
	adb reboot

}

if [ -z "$1" ]; then
	usage
	exit
fi

while [ ! -z "$1" ]; do
  case $1 in
	#build
	-k)
		build_kernel $2;
		break;;
	-f)
		flash_kernel $2;
		break;;
	-d)
		get $2;
		break;;
	-b)
		full_andrid_build $2;
		break;;
	-g)
		scratch $2 $3
		break;;
	-p)
		make_package $2
		break;;
	-v)
		make_shit
		break;;
	-v2)
		make_shit2
		break;;	
	-h)
		usage
		shift
		break;;
	*)
		usage
		break;;

  esac
	echo "aa"
  shift
done


