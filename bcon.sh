
rmmod bcmdhd

insmod /lib/modules/bcmdhd.ko firmware_path=/system/etc/firmware/fw_bcmdhd_4334.bin nvram_path=/system/etc/wifi/bcmdhd_4334.cal

sleep 2;

ifconfig wlan0 up 192.168.1.15

sleep 2;



