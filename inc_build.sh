
R2_DIR=~/r2
R3_DIR=~/r3
OUT=out/target/product/mfld_pr2

build_r3(){
	cd $DIR
	rm -rf $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/kernel-build.sh -c mfld_pr2 -o $DIR/$OUT/kernel_build
	if [ ! -e $DIR/$OUT/kernel_build/arch/x86/boot/bzImage ]; then
		echo "######  BUILD ERROR #####"
		exit
	fi

	cp $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/build_boot.sh  mfld_pr2 boot.bin
}

build_r2(){
	cd $DIR
	rm -rf $DIR/$OUT/kernel_build/arch/x86/boot/bzImage  $DIR/$OUT/boot/kernel
	$DIR/vendor/intel/support/kernel-build.sh -c mfld_pr2 -o $DIR/$OUT/kernel_build
	if [ ! -e $DIR/$OUT/kernel_build/arch/x86/boot/bzImage ]; then
		echo "######  BUILD ERROR #####"
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

flash(){
	fastboot flash boot $DIR/$OUT/boot.bin
	fastboot continue
}

if [ -z "$1" ]; then
	echo "invalid argument!"
        exit
fi

if [ $1 = "r3" ]; then
	DIR=$R3_DIR
	echo "BUILDING R3..."
	reboot
	build_r3
	flash

elif [ "$1" = "r2" ]; then
	DIR=$R2_DIR
	echo "BUILDING R2..."
	reboot
	build_r2
	flash
else
	echo "invalid argument!"
fi


