#!/bin/bash

CMD1=$1
CMD2=$2
BUILD_DIR=/home/mmes/dev/builds/entrynav
CECONN_DIR=/home/mmes/GITS/ceconn

#Personal build location
RPM_FOLDER="$BUILD_DIR/export/RPMS/armv6jel_vfp/"

#VM install script SCP source - ORIGINAL AKHELA
PLF_SCRIPT_ORIGINAL_AK="$CECONN_DIR/scripts/installceconnandroid.sh"
#VM install script SCP source - WITH NEW PLUGIN
PLF_SCRIPT_ORIGINAL_MM="$CECONN_DIR/scripts/installceconn_mm.sh"

#Platform install script SCP target - ORIGINAL AKHELA
PLF_SCRIPT_TARGET_AK='/opt/ceconn/bin/installceconnandroid.sh'
#Platform install script SCP target - WITH NEW PLUGIN
PLF_SCRIPT_TARGET_MM='/opt/ceconn/bin/installceconn_mm.sh'

cd $BUILD_DIR

#This script is always used to rebuild libmtp and ceconn modules
echo 'Paths are specific to the person who wrote the script!!!' 
echo $RPM_FOLDER
echo 'Run this script from you build folder!!!'

if [[ "$CMD1" == "-b"  || "$CMD2" == "-b" ]]; then 
	#Remove existing build
	echo '------------------'
	echo 'Cleaning libmtp'
	echo '------------------'
	make -C build libmtp.distclean

	echo '------------------'
	echo 'Cleaning ceconn'
	echo '------------------'
	rm $RPM_FOLDER/ceconn*.rpm
	make -C build ceconn.distclean

	echo '------------------'
	echo 'Rebuilding ceconn'
	echo '------------------'
	make -C build ceconn
fi

if [[ "$CMD1" == "-f"  || "$CMD2" == "-f" ]]; then 
	#Remove existing build
	echo '------------------'
	echo 'Copy source ceconn'
	echo '------------------'

	make -C build ceconn.distclean

	echo '------------------'
	echo 'Rebuilding ceconn'
	echo '------------------'
	make -C build ceconn
fi

#get RPM names from ls + grep, not devel nor debug versions
CECONN_RPM_NAME=`ls $RPM_FOLDER | grep ceconn | grep -v debug | grep -v devel`
LIBMTP_RPM_NAME=`ls $RPM_FOLDER | grep libmtp | grep -v debug | grep -v devel`  

if [[ "$CMD1" == "-i" || "$CMD2" == "-i" ]]; then 
	echo '-------------------------------'
	echo 'SCP RPMs into platform /var'
	echo '-------------------------------'
	#remove old ones if any
	sshpass -p 'root' ssh root@192.168.0.2 "rm -rf /var/ceconn.rpm /var/libmtp.rpm"

	echo $CECONN_RPM_NAME
	sshpass -p 'root' scp $RPM_FOLDER$CECONN_RPM_NAME root@192.168.0.2:/var/ceconn.rpm

	echo $LIBMTP_RPM_NAME
	sshpass -p 'root' scp $RPM_FOLDER$LIBMTP_RPM_NAME root@192.168.0.2:/var/libmtp.rpm

	echo '-------------------------------'
	echo 'Remount /opt with write rights'
	echo '-------------------------------'
	sshpass -p 'root' ssh root@192.168.0.2 "mount -o rw,remount /opt"

	echo '-------------------------------------------'
	echo 'SCP the install script to /opt/ceconn/bin'
	echo '-------------------------------------------'
	sshpass -p 'root' scp $PLF_SCRIPT_ORIGINAL_MM root@192.168.0.2:$PLF_SCRIPT_TARGET_MM


	echo '-------------------------------'
	echo 'Launch ceconn install script'
	echo '-------------------------------'
	sshpass -p 'root' ssh root@192.168.0.2 "chmod +x $PLF_SCRIPT_TARGET_MM;$PLF_SCRIPT_TARGET_MM /var/ceconn.rpm"

	echo '-------------------------------------'
	echo 'RPM2CPIO for libmtp - must run from /'
	echo '-------------------------------------'
	sshpass -p 'root' ssh root@192.168.0.2 "cd /; mount -o rw,remount /opt;rpm2cpio /var/libmtp.rpm|cpio -imdvu;sync;sync"

	echo '-------------------------------'
	echo 'PLEASE REBOOT PLATFORM'
	echo '-------------------------------'
fi

cd -
