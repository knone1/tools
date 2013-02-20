insmod /lib/modules/bcmdhd.ko firmware_path=/system/etc/firmware/fw_bcmdhd_4334.bin nvram_path=/system/etc/wifi/bcmdhd_4334.cal 
sleep 2
busybox ifconfig wlan0 up 192.168.2.15
sleep 2
/data/wlx join BUFFALO-2G


