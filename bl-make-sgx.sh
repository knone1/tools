
PAR1=$1

if [ "$PAR1" = "2" ]; then

export PATH=/home/axelh/aosp/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin:$PATH
AOSP=aosp-l
make TARGET_PRODUCT=beagleboneblack OMAPES=4.x ANDROID_ROOT_DIR=$HOME/$AOSP W=1; 
make TARGET_PRODUCT=beagleboneblack OMAPES=4.x ANDROID_ROOT_DIR=$HOME/$AOSP W=1 install; 
sudo mount /dev/mmcblk0p5 ./tmp ;
sudo cp ~/$AOSP/device/ti/beagleboneblack/sgx/system/* ./tmp/ -r;
sync; sudo umount ./tmp; sync

fi


if [ "$PAR1" = "1" ]; then

export PATH=/home/axelh/aosp-l/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin:$PATH
AOSP=aosp-l

if [ "$2" = "c" ]; then
make TARGET_PRODUCT=beagleboneblack OMAPES=4.x ANDROID_ROOT_DIR=$HOME/$AOSP W=1 clean;
fi
make TARGET_PRODUCT=beagleboneblack OMAPES=4.x ANDROID_ROOT_DIR=$HOME/$AOSP W=1; 
make TARGET_PRODUCT=beagleboneblack OMAPES=4.x ANDROID_ROOT_DIR=$HOME/$AOSP W=1 install; 
sudo mount /dev/mmcblk0p2 ./tmp ;
sudo cp ~/$AOSP/device/ti/beagleboneblack/sgx/system/* ./tmp/system/ -r;
sync; sudo umount ./tmp; sync

fi


