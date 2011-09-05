#!/bin/bash

#VARIABLES - NO RELATIVE PATHS PLEASE!
DIR=~/emmcFiles #Where the files are extracted 
FORDATA=$DIR/forData #Files to be copied to data part
FORSYS=$DIR/forSys #Files to copy to system partition
KDIR=~/bin #kernel dir to get the kernel from
ICEDIR=/home/axel/SMBSHARES/YELLOW/ics/out/target/product/blaze
#TUNADIR=/home/axel/SMBSHARES/YELLOW/ics/out/target/product/tuna
#TUNADIR=/home/axel/bin/tuna
TUNADIR=/home/axelh/tuna/14july


echo "**********************************"
echo "CONFIGURATION"
echo "**********************************"
echo "DIR = "$DIR
echo "FORDATA = "$FORDATA
echo "FORSYS = "$FORSYS
echo "KDIR = "$KDIR
echo "TUNADIR = "$TUNADIR
echo "**********************************"

if [ ! -d "$DIR" ]; then
mkdir -p $DIR
mkdir -p $DIR/forData
mkdir -p $DIR/forSys
fi
cd $DIR


#----------------------------------------------
# HELPER FUNCTIONS
#----------------------------------------------
makeSys () 
{
	cd $DIR/files
	if [ -e $FORSYS ];then
		sudo cp $FORSYS/* ./system/
		sudo ./make_ext4fs -s -l 512M -a system system.img system/
	fi
}
makeData () 
{
	cd $DIR/files
	if [ -e $FORDATA ];then
		sudo cp $FORDATA/* ./user/
		sudo ./make_ext4fs -s -l 512M -a userdata userdata.img user/
	fi
}
makeAll () 
{
	makeSys;
	makeData;
}

CleanFiles()
{
	echo "**********************************"
	echo "CLANING..."
	echo "**********************************"
	sudo umount $DIR/files/system
	sudo umount $DIR/files/user
	sudo rm -rf $DIR/files 
	sudo rm -rf $DIR/OPBU_BR_eMMC_binaries_*

}

downloadFiles()
{
	http_proxy= 
	LABEL=$1
	URL=http://omapssp.dal.design.ti.com/VOBS/CSSD_Linux_Releases/4430/Linux_27.x/PDB/DailyBuilds/$LABEL/binaries
	echo "**********************************"
	echo "DOWNLOADING..."
	echo "**********************************"
	wget $URL/OPBU_BR_eMMC_binaries_$LABEL.tar.bz2 

}

extractFiles()
{
	echo "**********************************"
	echo "EXTRACTING..."
	echo "**********************************"
	cd $DIR
	tar xjvf ./OPBU_BR_eMMC_binaries_$LABEL.tar.bz2
	cd -
	mv $DIR/emmc_* $DIR/files

}

mountImages()
{
	cd $DIR/files

	if [ ! -e $DIR/files ];then
		echo "ERROR: NO $DIR/files DIRECTORY!"
		exit 1
	fi

	sudo umount system
	rm -rf system
	mkdir system
	./simg2img system.img system.img.raw
	sudo mount -t ext4 -o loop system.img.raw system/

	sudo umount user
	rm -rf user
	mkdir user
	./simg2img userdata.img userdata.img.raw
	 sudo mount -t ext4 -o loop userdata.img.raw user/
	
	rm -rf boot
	mkdir boot
	cp ramdisk.img ramdisk.img.bkup
	cd ./boot
	gunzip -c ../ramdisk.img | cpio -i
}

#----------------------------------------------
getIceBinaries () 
{

	CleanFiles
	
	if [ ! -e $DIR/OPBU_BR_eMMC_binaries_$LABEL.tar.bz2 ];then

		downloadFiles $1
		extractFiles


		cd $DIR/files
		
		if [ ! -e $DIR/files ];then
			exit 1
		fi

		echo "**********************************"
		echo "GETTING ICE FILE..."
		echo "**********************************"


		cp $ICEDIR/*.img ./

		mountImages
		
		cd $DIR/files
		
		while [ ! -e $KDIR/zImage ];do
			sleep 1
		done	
		cp $KDIR/zImage ./
		umulti.sh
		
		cp $DIR/files/MLO_es1.0_emu $DIR/files/MLO_es2.2_emu	

		# Modify images with user content.
		makeAll;
		sudo ./fastboot.sh --emu

	fi

}

#----------------------------------------------
getTunaBinaries () 
{
	CleanFiles
	downloadFiles $1
	extractFiles

	cd $DIR/files

	if [ ! -e $DIR/files ];then
		exit 1
	fi

	echo "**********************************"
	echo "GETTING TUNA FILE..."
	echo "**********************************"

	cp $TUNADIR/*.img ./

	mountImages
	
	cd $DIR/files
	while [ ! -e $KDIR/zImage ];do
		echo "WAITING FOR KERNEL..."
		sleep 1
	done	
	cp $KDIR/zImage ./
	
	cp $DIR/forBuild/* $DIR/files
	umulti-tuna.sh	

	# Modify images with user content.
	makeAll;
	
	cd $DIR/files
	sudo ./fastboot flash boot 		./boot.img
	sudo ./fastboot flash recovery	./recovery.img
	sudo ./fastboot flash system 	./system.img
	sudo ./fastboot flash userdata 	./userdata.img
}

flashTuna()
{
	cd $DIR/files
	export ftp_proxy=
	wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/$1/*
	sudo ./fastboot flash boot 	boot.img
	sudo ./fastboot flash recovery	recovery.img
	sudo ./fastboot flash system 	system.img
	sudo ./fastboot flash userdata 	userdata.img
	
}

flashTunaBoot()
{
	cd $DIR/files
	cp $TUNADIR/bootloader.img ./
	sudo ./fastboot flash bootloader ./bootloader.img
 	sudo ./fastboot reboot-bootloader
}



#----------------------------------------------
getBinaries () 
{
	CleanFiles
	downloadFiles $1
	extractFiles

	cd $DIR/files

	if [ ! -e $DIR/files ];then
		exit 1
	fi
	
	mountImages

	# Modify images with user content.
	makeAll
	sudo ./fastboot.sh --emu

}


#----------------------------------------------
flashKernel () 
{
	echo "**********************************"
	echo "REPLACE KERNEL..."
	echo "**********************************"
	cd $DIR/files
	cp ~/SMB/YELLOW/bin/zImage $KDIR
	while [ ! -e $KDIR/zImage ];do
		sleep 1
	done	
	cp $KDIR/zImage ./
	./umulti.sh	
	sudo ./fastboot flash boot ./boot.img
}
flashKernelTuna () 
{
	adb reboot-bootloader
	echo "**********************************"
	echo "REPLACE KERNEL TUNA..."
	echo "**********************************"
#	cp ~/SMB/YELLOW/bin/zImage $KDIR
	cp $KDIR/zImage ./
	cd $DIR/files
	cp  ~/bin/zImage $DIR/files
	./umulti-tuna.sh	
	sudo ./fastboot flash boot ./boot.img
	sudo ./fastboot reboot
}
#----------------------------------------------
flashBoot () {
	echo "**********************************"
	echo "REPLACE BOOT..."
	echo "**********************************"
	cd $DIR/files
	cd ./boot
	find . | cpio -o -H newc | gzip > ../ramdisk.img
	cd ..
	umulti.sh
	sudo ./fastboot flash boot ./boot.img
}

#----------------------------------------------
flashSystem () {
	echo "**********************************"
	echo "REPLACE SYSTEM..."
	echo "**********************************"
	cd $DIR/files
	makeSys;
	sudo ./fastboot flash system	./system.img
}

#----------------------------------------------
flashData () {
	echo "**********************************"
	echo "REPLACE DATA..."
	echo "**********************************"
	cd $DIR/files
	makeData;
	sudo ./fastboot flash userdata	./userdata.img
}
#----------------------------------------------
# TORO
#----------------------------------------------
flashToro () {
	cd $DIR/files
	cp ../forBuild/* ./
	# 1) flash latest bootloader
	sudo ./fastboot flash bootloader bootloader.img
	sudo ./fastboot reboot-bootloader
	sleep 5
	# 2) FLASH MODEM IMAGE
	sudo ./fastboot flash radio radio.img
	# only on LTE board needed
	sudo ./fastboot flash radio-cdma radio-cdma.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 3) FLASH SYSTEM IMAGE
	sudo ./fastboot flash boot boot.img
	sudo ./fastboot flash system system.img
	sudo ./fastboot flash userdata userdata.img
	sudo ./fastboot flash recovery recovery.img

	# 4) REBOOT new image
	sudo ./fastboot reboot


}
getToroBinaries () {
	cd $DIR/files
	rm -rf *
	export ftp_proxy=
	wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/$1/toro-lte/*	
	flashToro
}

mkTunaBusyBox () {
	cd $DIR/files
	sudo umount ./boot
	rm -rf ./boot
	mkdir boot
	cp -rf ramdisk.img ramdisk.img.bkup
	cd ./boot
	gunzip -c ../ramdisk.img | cpio -i
	rm -rf *
	cp -rf ~/p-android/sdp_bb/* ./
	find . | cpio -o -H newc | gzip > ../ramdisk.img
        	
}

#----------------------------------------------
# TUNA
#----------------------------------------------
flashTuna2 () {
	cd $DIR/files
	# 1) flash latest bootloader
	sudo ./fastboot flash bootloader bootloader.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 2) FLASH MODEM IMAGE
	sudo ./fastboot flash radio radio.img
	# only on LTE board needed
	sudo ./fastboot flash radio-cdma radio-cdma.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 3) FLASH SYSTEM IMAGE
	sudo ./fastboot flash boot boot.img
	sudo ./fastboot flash system system.img
	sudo ./fastboot flash userdata userdata.img
	sudo ./fastboot flash recovery recovery.img

	# 4) REBOOT new image
	sudo ./fastboot reboot

}
getTunaBinaries2 () {
	cd $DIR/files
	sudo umount *
	rm -rf *
	export ftp_proxy=
	wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/$1/maguro-hspa/*	
	cp ../forBuild/* ./	
	flashTuna2
}

ggtuna () {
	cd $DIR/files
	sudo umount *
        rm -rf *
        export ftp_proxy=
        wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/google/$1/HSPA-maguro/*
	wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/google/$1/LTE-toro/ramdisk.img
	cp ../forBuild/* ./
	unzip *.zip

	# 1) flash latest bootloader
	sudo ./fastboot flash bootloader bootloader.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 2) FLASH MODEM IMAGE
	sudo ./fastboot flash radio radio.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 3) FLASH SYSTEM IMAGE
	sudo ./fastboot flash boot boot.img
	sudo ./fastboot flash system system.img
	sudo ./fastboot flash userdata userdata.img
	sudo ./fastboot flash recovery recovery.img

	# 4) REBOOT new image
	sudo ./fastboot reboot

}
ggtoro () {
	cd $DIR/files
	sudo umount *
        rm -rf *
        export ftp_proxy=
	wget ftp://sgda0876558-ubuntu.am.dhcp.ti.com/userbin/google/$1/LTE-toro/*

	cp ../forBuild/* ./
	unzip *.zip

	# 1) flash latest bootloader
	sudo ./fastboot flash bootloader bootloader.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 2) FLASH MODEM IMAGE
	sudo ./fastboot flash radio radio.img
	# only on LTE board needed
	sudo ./fastboot flash radio-cdma radio-cdma.img
	sudo ./fastboot reboot-bootloader
	sleep 5

	# 3) FLASH SYSTEM IMAGE
	sudo ./fastboot flash boot boot.img
	sudo ./fastboot flash system system.img
	sudo ./fastboot flash userdata userdata.img
	sudo ./fastboot flash recovery recovery.img

	sudo ./fastboot reboot
}




#----------------------------------------------
flashAll () {
	echo "**********************************"
	echo "FASTBOOT ALL..."
	echo "**********************************"
	cd $DIR/files
#	makeAll;
	sudo ./fastboot.sh --emu
}
usage () 
{
	echo "USAGE: emmcMake <options>"
	echo "-k : Flash Kernel : Take the kernel compiled in $KDIR and flash it"
	echo "-a : Flash All :run Fastboot.sh with all binaries in $DIR"
	echo "-s : Flash System :create system.img and flash it."
	echo "					all files added in $DIR/forSys will be added"
	echo "-d : Flash Data :create data.img and flash it."
	echo "					all files added in $DIR/forData will be added"
	echo "-b : Flash Boot :create boot.img and flash it."
	echo "-g <Label>: Get binearies : Download a DB and flash it"
	echo "             example: emmcMake.sh -g L27.x_Gingerbread_DailyBuild_202"
	echo "-ics replace with built images from dir $ICEDIR same usage as -g"
	echo "-tuna replace with built images from dir $TUNADIR same usage as -g"
	echo "emmcMake.sh -ggtuna IRK63D"
}



# parse commandline options
while [ ! -z "$1" ]; do
  case $1 in
	-h)usage;;
	-fk)flashKernel;;
	-a)flashAll;;
	-s)flashSystem;;
	-d)flashData;;
	-b)flashBoot;;
	-g)getBinaries $2;;
	-ics)getIceBinaries $2;;	
	-tuna)getTunaBinaries $2;;
	-ft)flashTuna $2;;
	-ftboot)flashTunaBoot;;		
	-ftk)flashKernelTuna;;
	-gtoro)getToroBinaries $2;;
	-ftoro)flashToro;;
	-gtuna)getTunaBinaries2 $2;;
	-ftuna)flashTuna2;;
	-tunabb) mkTunaBusyBox $2;;
	-ggtuna)ggtuna $2;;
	-ggtoro)ggtoro $2;;
  esac
  shift
done

