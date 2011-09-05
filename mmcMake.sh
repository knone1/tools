#!/bin/bash

#NUM=$1
DIR=~/bin/L27/tmp
http_proxy=


#PASTRY=Gingerbread
#PASTRY=Froyo
#LABEL=L27.x_"$PASTRY"_DailyBuild_"$NUM"

LABEL=$1

URL=http://omapssp.dal.design.ti.com/VOBS/CSSD_Linux_Releases/4430/Linux_27.x/PDB/DailyBuilds/$LABEL/binaries
#----------------------------------------------

if [ $# = 0 ];then
	echo ""
	echo "	mmcMake [DB_NUMBER] [-f]"
	exit 1
fi

if [ ! -e "/dev/sdb" ];then
	echo "no sd device node /dev/sdb"
	exit 1
fi

        echo "**********************************"
        echo " FOLDER NOT FOUND, DOWNLOADING..."
        echo "**********************************"
        mkdir $DIR
	cd $DIR
	rm -rf *
	wget $URL/OPBU_BR_AFS_$LABEL.tar.bz2 
	wget $URL/OPBU_BR_KNL_$LABEL.tar.bz2
	wget $URL/OPBU_BR_uBoot_$LABEL.tar.bz2
	wget $URL/OPBU_BR_xLoad_$LABEL.tar.bz2
#	chown axel.axel *
#	chmod 766 * 




#-------------------------------------------------------------------------------

sudo umount /media/*
sudo rm -rf /media/boot
sudo rm -rf /media/fileSystem


if [ $2 == "-f" ];then
	echo "**********************"
	echo " Formating"
	echo "**********************"
	cd /home/axel
	sudo /home/axel/omap_format_sd.pl /dev/sdb
fi


#-------------------------------------------------------------------------------

echo "**********************"
echo " Mounting"
echo "**********************"
sudo mkdir /media/boot
sudo mkdir /media/fileSystem

sudo mount -t vfat -o umask=0000,utf8 /dev/sdb1 /media/boot
sudo mount -t ext3 /dev/sdb2 /media/fileSystem

sudo chmod 777 /media/fileSystem
sudo chmod 777 /media/boot

echo "**********************"
echo " Cleaning"
echo "**********************"
cd /media/fileSystem
sudo rm -rf *
cd /media/boot
sudo rm -rf *
sync

echo "**********************"
echo " copy boot"
echo "**********************"
cd /media/boot

tar xjvf  $DIR/OPBU_BR_xLoad*
tar xjvf  $DIR/OPBU_BR_uBoot*
tar xjvf  $DIR/OPBU_BR_KNL*

cp ./es2.2_emu_MLO ./MLO
sync
cp ./uImage* ./uImage
sync
cp -rf /home/axel/bin/forBoot/* ./
sync



echo "**********************"
echo " extracting FS"
echo "**********************"
cd /media/fileSystem
tar xjvf $DIR/OPBU_BR_AFS_* --strip 2
cp -rf /home/axel/bin/forFs/* ./
touch THIS_IS_DB_$NUM
sync

#-------------------------------------------------------------------------------

cd /media
sudo umount /media/*
sudo rm -rf /media/boot
sudo rm -rf /media/fileSystem
cd /home/axel



echo "**********************"
echo " Done"
echo "**********************"


