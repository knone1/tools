rm -rf *
repo init -u git://android.intel.com/manifest -b platform/android/main -m android-main
repo sync -j8
source ./build/envsetup.sh
lunch ctpscaleht-eng
make -j8 flashfiles
make -j8 blank_flashfiles


