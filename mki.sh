DIR=~/r3
OUT=out/target/product/mfld_pr2

# R3 INFO #
R3_DIR=~/r3
R3_RELEASE=2012_WW08
R3_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r3/android/ice-cream-sandwich-platform/releases
R3_MANIFEST=$R3_URL/$R3_RELEASE/manifest-$R3_RELEASE-generated.xml

# R2 INFO #
R2_DIR=~/r2
R2_RELEASE=2012_WW08
R2_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r2/android/gingerbread-platform/releases
R2_MANIFEST=$R2_URL/$R2_RELEASE/manifest-$R2_RELEASE-generated.xml

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
	else
		DIR=$R3_DIR
	fi
	cd $DIR

}

full_andrid_build(){
	set_dir $1
        source build/envsetup.sh
        lunch mfld_pr2-eng
        make -j8 mfld_pr2
}

build_boottarball(){
	cd $DIR

	rm -rf $DIR/out/target/product/mfld_pr2/boot.bin
	rm -rf $DIR/out/target/product/mfld_pr2/kernel_build/arch/x86/boot/bzImage
	rm -rf $DIR/out/target/product/mfld_pr2/kernel_build/arch/i386/boot/bzImage
	rm -rf $DIR/out/target/product/mfld_pr2/bzImage
	source build/envsetup.sh
	lunch mfld_pr2-eng
	make -j4 boottarball	
}

build_r3(){
	cd $DIR
	rm -rf $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/kernel-build.sh -c mfld_pr2 -o $DIR/$OUT/kernel_build
	if [ ! -e $DIR/$OUT/kernel_build/arch/x86/boot/bzImage ]; then
		print "######  BUILD ERROR #####"
	exit
	fi

	
	vendor/intel/support/mkbootimg --cmdline "init=/init pci=noearly console=ttyMFD3 console=logk0 earlyprintk=nologger loglevel=4 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on apic=debug"  --ramdisk $OUT/boot/ramdisk.img \
	--kernel $OUT/kernel_build/arch/i386/boot/bzImage \
	--output $OUT/boot.bin \
	--product mfld_pr2 \
	--type mos
	
}

build_r2(){
	cd $DIR
	rm -rf $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/kernel-build.sh -c mfld_pr2 -o $DIR/$OUT/kernel_build
	if [ ! -e $DIR/$OUT/kernel_build/arch/x86/boot/bzImage ]; then
		print "######  BUILD ERROR #####"
		exit
	fi

	cp $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	vendor/intel/support/mkbootimg --cmdline "init=/init pci=noearly console=ttyMFD3 earlyprintk=nologger loglevel=8 hsu_dma=7 kmemleak=off androidboot.bootmedia=sdcard androidboot.hardware=mfld_pr2 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on" \
	--ramdisk $OUT/boot/ramdisk.img \
	--kernel $OUT/kernel_build/arch/i386/boot/bzImage \
	--output $OUT/boot.bin \
	--product mfld_pr2 \
	--type mos
}

reboot(){
	print "REBOOT"
	adb shell "update_osip --backup --invalidate 1; reboot"
#	adb reboot-bootloader
	

}

flash_boot()
{
	print "FLASH"
	sudo fastboot flash boot $DIR/out/target/product/mfld_pr2/boot.bin
	sudo fastboot continue
}



build_kernel()
{
	reboot
	print "BUILDING $1"

	if [ "$1" = "r3" ]; then
		DIR=$R3_DIR
		build_r3
	elif [  "$1" = "r2" ]; then
		DIR=$R2_DIR
		build_r2
	elif [ "$1" = "boottarball_r3" ]; then
		DIR=$R3_DIR
		build_boottarball
	elif [ "$1" = "boottarball_r2" ]; then
		DIR=$R2_DIR
		build_boottarball	
	else
		print " BUILDING DEFAULT R3"
		DIR=$R3_DIR
		build_r3
	fi
	flash_boot
}

flash_kernel()
{
	reboot
	set_dir $1
	cd $DIR
	flash_boot
}

flash()
{
	cd ~/DB/CURRENT/IMAGE
	fastboot oem system /sbin/PartitionDisk.sh /dev/mmcblk0
	
        sudo fastboot flash boot boot.bin
        sudo fastboot flash recovery recovery.img
        sudo fastboot flash radio radio_firmware.bin
        sudo fastboot erase system
        sudo fastboot flash system system.tar.gz
        sudo fastboot flash dnx SIGNED_PNW_C0_D0_FWR_DnX.FD.24.bin
        sudo fastboot flash ifwi IFWI_v02.16_CRAK.bin

}

#GET DAILY BUILD AND FLASHIT
get(){

	export http_proxy=

	case $1 in 
	r2)

		THIS_RELEASE=$R2_RELEASE
		THIS_URL=$R2_URL
		THIS_DIR=~/DB/R2/$R2_RELEASE
		;;
	r3)
		THIS_RELEASE=$R3_RELEASE
		THIS_URL=$R3_URL
		THIS_DIR=~/DB/R3/$R3_RELEASE
		;;
	esac
	
	if [ -e $THIS_DIR ]; then
		echo "$THIS_DIR exists."
		exit 1;
	fi
	mkdir -p $THIS_DIR
	cd $THIS_DIR
	print "get system file."
	wget -r -l1 --no-parent -A"*fastboot*.zip"  http://$THIS_URL/$THIS_RELEASE/MFLD_PRx/flash_files/build-eng/
	mv $THIS_URL/$THIS_RELEASE/MFLD_PRx/flash_files/build-eng/* .
	rm -rf jfumgbuild-depot.jf.intel.com
	print "get PR3.1 blankphone."
	wget -r -l1 --no-parent -A"*PR3.1*.zip" http://$THIS_URL/$THIS_RELEASE/MFLD_PRx/flash_files/blankphone/
	mv $THIS_URL/$THIS_RELEASE/MFLD_PRx/flash_files/blankphone/* .
	rm -rf jfumgbuild-depot.jf.intel.com

}

#SYNC REPO TO A RELEASE
sync(){

	cd $DIR

	case $1 in 
	r2) 	wget http://jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r2/android/gingerbread-platform/releases/$R2_RELEASE/manifest-$R2_RELEASE-generated.xml
		RELEASE=$R2_RELEASE 
		;;
	r3)	 wget	http://jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r3/android/ice-cream-sandwich-platform/releases/$R3_RELEASE/manifest-$R3_RELEASE-generated.xml
		RELEASE=$R3_RELEASE
		;;
	*)exit 1;;
	esac

	cp ./manifest-$RELEASE-generated.xml ./.repo/manifests
	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./.repo/manifests//manifest-$RELEASE-generated.xml
	cd $DIR
	repo init -m manifest-$RELEASE-generated.xml 
	repo sync -d
}
sync_clean_build_full()
{
	sync r3
	clean_build_full r3
}

scratch_r3()
{
	
	print "SCRATCH R3"

	if [ -e ~/RELEASES/R3/$R3_RELEASE ]; then
		print "$R3_RELEASE BUILD EXISTS PLEASE REMOVE IT."
		exit
	fi

        mkdir -p ~/RELEASES/R3/$R3_RELEASE
        cd ~/RELEASES/R3/$R3_RELEASE

	print "REPO INIT"
	repo init -u git://android.intel.com/manifest -b platform/android/main -m android-main
	
	print "GET MANIFEST"
        wget $R3_MANIFEST
        MANIFEST=`ls *.xml`
        sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST

	
        cp  $MANIFEST ./.repo/manifests
	print "REPO INIT MANIFEST:"
        repo init -m  $MANIFEST

	print "REPO SYNC"
        repo sync

	print "BUILD"
        vendor/intel/support/build_all.sh -c mfld_pr2
}

scratch_r2()
{
	print "SCRATCH R2"
	if [ -e ~/RELEASES/R2/$R2_RELEASE ]; then
		print " ~/RELEASES/R2/$R2_RELEASE BUILD EXISTS PLEASE REMOVE IT."
		exit
	fi

        mkdir -p ~/RELEASES/R2/$R2_RELEASE
        cd ~/RELEASES/R2/$R2_RELEASE
	repo init -u git://android.intel.com/manifest -b gingerbread -m stable

	print "GET MANIFEST"
	wget $R2_MANIFEST
	MANIFEST=`ls *.xml`
	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST
	cp  $MANIFEST ./.repo/manifests

	print " REPO INIT"
	repo init -m  $MANIFEST
	print "REPO SYNC"
	repo sync
	print "BUILD"
	vendor/intel/support/build_all.sh -c mfld_pr2



}

usage(){
	echo 	" usage is:
		where x is r2 || r3
		-k) build_kernel:
			x: incremental kernel-only build
			boottarball_x: kernel + modules build
			example:
				mki.sh -k boottarball_r3
				mki.sh -k r2
		
		-fk) flash_kernel
			flash currently built boot.img
			example:
				mki.sh -fk r3
				mki.sh -fk r2
		-s_x) get code and build EVERYTHING!
			example:
				mki.sh -s_r3
				mki.sh -s_r2

			requires these set on mki.sh, check inside for example!
			R2_RELEASE
			R2_URL
			R2_MANIFEST
					
		--full_andrid_build x) runs make at top dir
			example:
				mki.sh --full_andrid_build r3

		--get_release x) get DB for flash.
			example:	
				mki.sh --get_release r3
		"
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
	-fk)
		flash_kernel $2;
		break;;
	--get_release)
		get $2;
		break;;
	--full_andrid_build)
		full_andrid_build $2;
		break;;
	-s_r3)
		scratch_r3
		break;;
	-s_r2)
		scratch_r2
		break;;
	-v)
		make_shit
		break;;	
	*)
		usage
		break;;

  esac
  shift
done


