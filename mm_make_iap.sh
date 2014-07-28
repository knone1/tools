#!/bin/bash

CMD1=$1
CMD2=$2
BUILD_DIR=/home/mmes/build
CECONN_DIR=/home/mmes/GITS/iap

#Personal build location
RPM_FOLDER="$BUILD_DIR/export/RPMS/armv6jel_vfp/"

#VM install script SCP source - WITH NEW PLUGIN
PLF_SCRIPT_ORIGINAL="$CECONN_DIR/dist/scripts/install_iap.sh"

#Platform install script SCP target - WITH NEW PLUGIN
PLF_SCRIPT_TARGET='/opt/ceconn/bin/install_iap.sh'

cd $BUILD_DIR

#This script is always used to rebuild libmtp and ceconn modules
echo 'Paths are specific to the person who wrote the script!!!'
echo $RPM_FOLDER
echo 'Run this script from you build folder!!!'

if [[ "$CMD1" == "-b"  || "$CMD2" == "-b" ]]; then
	#Remove existing build
	echo '------------------'
	echo 'Cleaning iap'
	echo '------------------'
	rm -rf $RPM_FOLDER/iap-*
	make -C build iap.distclean

	echo '------------------'
	echo 'Rebuilding iap'
	echo '------------------'
	make -C build iap
fi

#get RPM names from ls + grep, not devel nor debug versions
RPM_NAME=`ls $RPM_FOLDER | grep iap | grep -v debug | grep -v devel`

echo $RPM_NAME

if [[ "$CMD1" == "-i" || "$CMD2" == "-i" ]]; then 
	echo '-------------------------------'
	echo 'SCP RPM into platform /var'
	echo '-------------------------------'
	#remove old ones if any
	sshpass -p 'root' ssh root@192.168.0.2 "rm -rf /var/iap.rpm /var/iap.rpm"

	sshpass -p 'root' scp $RPM_FOLDER$RPM_NAME root@192.168.0.2:/var/iap.rpm

	echo '-------------------------------'
	echo 'Remount /opt with write rights'
	echo '-------------------------------'
	sshpass -p 'root' ssh root@192.168.0.2 "mount -o rw,remount /opt"

	echo '-------------------------------------------'
	echo 'SCP the install script to /opt/ceconn/bin'
	echo '-------------------------------------------'
	sshpass -p 'root' scp $PLF_SCRIPT_ORIGINAL root@192.168.0.2:$PLF_SCRIPT_TARGET

	echo '-------------------------------'
	echo 'Launch iap install script'
	echo '-------------------------------'
	sshpass -p 'root' ssh root@192.168.0.2 "chmod +x $PLF_SCRIPT_TARGET;$PLF_SCRIPT_TARGET /var/iap.rpm"

	echo '-------------------------------'
	echo 'PLEASE REBOOT PLATFORM'
	echo '-------------------------------'
fi

cd -
