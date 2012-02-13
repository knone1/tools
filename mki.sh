DIR=~/r3
OUT=out/target/product/mfld_pr2

# R3 INFO #
R3_DIR=~/r3
R3_RELEASE=2012WW04
R3_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r3/android/ice-cream-sandwich-platform/releases
R3_MANIFEST=$R3_URL/$R3_RELEASE/manifest-$R3_RELEASE-generated.xml

# R2 INFO #
R2_DIR=~/r2
R2_RELEASE=2012_WW04
R2_URL=jfumgbuild-depot.jf.intel.com/build/eng-builds/mfld-r2/android/gingerbread-platform/releases
R2_MANIFEST=$R2_URL/$R2_RELEASE/manifest-$R2_RELEASE-generated.xml

#START A FULL BUIL
print(){
	echo "#######################################################"
	echo $1
	echo "#######################################################"
}

full_andrid_build(){
	cd $DIR
        source build/envsetup.sh
        lunch mfld_pr2-eng
        make -j4 clean
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

	cp $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/build_boot.sh  mfld_pr2 boot.bin
	mv  $DIR/boot.bin $DIR/$OUT/
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
	vendor/intel/support/mkbootimg --cmdline cmdline \
	--ramdisk $OUT/boot/ramdisk.img \
	--kernel $OUT/kernel_build/arch/i386/boot/bzImage \
	--output $OUT/boot.bin \
	--product mfld_pr2 \
	--type mos
}

reboot(){
	adb shell "update_osip --backup --invalidate 1; reboot"
}

flash_boot(){
	sudo fastboot flash boot $DIR/out/target/product/mfld_pr2/boot.bin
	sudo fastboot continue
}

set_dir(){

	if [ "$1" = "r3" ]; then
		DIR=$R3_DIR
	elif [  "$1" = "r2" ]; then
		DIR=$R2_DIR
	else
		DIR=$R3_DIR
	fi
	cd $DIR

}

build_kernel(){
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
	set_dir $1
	cd $DIR
	reboot
	flash_boot
}

flash(){
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

	cd ~/DB
	rm -rf CURRENT
	mkdir CURRENT
	cd CURRENT
	export http_proxy=

	if [ -z $1 ]; then
		echo "add ww folder example: 2012_WW04"
		exit 1;
	fi
	mkdir IMAGE
	mkdir BLANK

	#GET IMAGE
	case $1 in 
	r2)
		wget -r -l1 --no-parent -A"*fastboot*.zip" http://$R2_URL/$R2_RELEASE/MFLD_PRx/flash_files/build-eng/	
		mv $R2_URL/$R2_RELEASE/MFLD_PRx/flash_files/build-eng/* .
		rm -rf jfumgbuild-depot.jf.intel.com
		cd IMAGE unzip ../*fastboot*.zip
	
		#BLANK PHONE
		wget -r -l1 --no-parent -A"*PR3.1*.zip" http://$R2_URL/releases/$R2_RELEASE/MFLD_PRx/flash_files/blankphone/
		mv $R2_URL/$R2_RELEASE/MFLD_PRx/flash_files/blankphone/* . 
		rm -rf jfumgbuild-depot.jf.intel.com ;;
	r3)
		wget -r -l1 --no-parent -A"*PR3.1*.zip"  http://$R3_URL/$R3_RELEASE/MFLD_PRx/flash_files/build-eng/
	        mv $R3_URL/$R3_RELEASE/MFLD_PRx/flash_files/build-eng/* .
        	rm -rf jfumgbuild-depot.jf.intel.com
		cd IMAGE
		unzip ../*PR3.1*.zip
	        #BLANK PHONE
        	wget -r -l1 --no-parent -A"*PR3.1*.zip" http://$R3_URL/$R3_RELEASE/MFLD_PRx/flash_files/blankphone/
	        mv $R3_URL/$R3_RELEASE/MFLD_PRx/flash_files/blankphone/* .
        	rm -rf jfumgbuild-depot.jf.intel.com 
	;;
	esac

	cd ../BLANK
	unzip ../*blank*.zip
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

scratch(){
	 print "*BULDING R2 "

	rm -rf ~/r2_scratch
	mkdir ~/r2_scratch
	cd ~/r2_scratch

	repo init -u git://android.intel.com/manifest -b gingerbread -m stable
	wget $R2_MANIFEST
	MANIFEST="ls *.xml"
	sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST
	cp  $MANIFEST ./.repo/manifests
	repo init -m  $MANIFEST
	repo sync
	vendor/intel/support/build_all.sh -c mfld_pr2

	print  "*BULDING R3"

	rm -rf ~/r3_scratch
        mkdir ~/r3_scratch
        cd ~/r3_scratch

	repo init -u git://android.intel.com/manifest -b platform/android/main -m android-main
        wget $R3_MANIFEST
        MANIFEST="ls *.xml"
        sed -i 's/jfumg-gcrmirror.jf.intel.com/ncsgit001.nc.intel.com/g' ./$MANIFEST
        cp  $MANIFEST ./.repo/manifests
        repo init -m  $MANIFEST
        repo sync
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
		"
}

if [ -z "$1" ]; then
	usage
	exit
fi

while [ ! -z "$1" ]; do
  case $1 in
	#build
	-k)build_kernel $2;
		shift;
		;;
	-fk)flash_kernel $2;
		shift;
		;;	
	*)usage;;

  esac
  shift
done


