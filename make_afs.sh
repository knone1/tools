MYDROID=~/src
cd ~/
rm -rf myfs
mkdir myfs
cd myfs
#cp -Rfp $MYDROID/kernel/android-2.6.29/drivers/usb/gadget/*.ko $MYDROID/out/target/product/zoom2/root
#cp -Rfp $MYDROID/kernel/android-2.6.29/drivers/misc/ti-st/*.ko $MYDROID/out/target/product/zoom2/root
cp -Rfp $MYDROID/out/target/product/zoom2/root/* .
cp -Rfp $MYDROID/out/target/product/zoom2/system/ .
cp -Rfp $MYDROID/out/target/product/zoom2/data/ .
mv init.rc init.rc.bak
cp -Rfp $MYDROID/device/ti/zoom2/omapzoom2-mmc.rc init.rc
