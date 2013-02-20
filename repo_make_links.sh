

rm bcm4334;ln -s ./hardware/broadcom/wlan_driver/bcm4334 bcm4334
rm bcm4335;ln -s ./hardware/broadcom/wlan_driver/bcm4335 bcm4335
rm kernel;ln -s ./hardware/intel/linux-2.6 kernel
rm blackbay_out;ln -s ./out/target/product/blackbay blackbay_out
rm fw fw;ln -s ./device/intel/fw/wifi_bcm/bcm4334 fw

