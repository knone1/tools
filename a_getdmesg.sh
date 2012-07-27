adb shell "dmesg > /data/dmesg.txt"
adb pull /data/dmesg.txt ./dmesg.txt
