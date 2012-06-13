
CDIR=$PWD
BRANCH=wifi_ctp
#BRANCH=main

cd hardware/intel/PRIVATE/wpa_supplicant_8
git checkout $BRANCH;git reset --hard HEAD~50;git pull
cd $CDIR/hardware/ti/wlan
git checkout $BRANCH;git reset --hard HEAD~50;git pull
cd $CDIR/device/intel/fw/wifi
git checkout $BRANCH;git reset --hard HEAD~50;git pull
cd $CDIR/external/iw
git checkout $BRANCH;git reset --hard HEAD~50;git pull
cd $CDIR/vendor/intel/PRIVATE/manifest
git checkout $BRANCH;git reset --hard HEAD~50;git pull
cd $CDIR/hardware/intel/linux-2.6
git checkout k303x;git reset --hard HEAD~50;git pull

if [ $BRANCH = "wifi_ctp" ];then
	git am $CDIR/0001-WLAN-TI-R5.00.08-official-delivery-Calibrator.patch
fi

