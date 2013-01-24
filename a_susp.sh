
adb shell "echo 0 > /sys/kernel/debug/alarm-backoff/threshold"
adb shell "echo 0 > /sys/kernel/debug/suspend-backoff/threshold"
echo "while true;do cat /proc/wakelocks | awk '{print \$1 \" \" \$5}' |grep -v \" 0\" |grep -v active; echo \"______\";sleep 1;done;" >s.sh
chmod 777 ./s.sh
adb push ./s.sh /data
adb shell "/data/s.sh&"
adb shell "echo \"init=/init pci=noearly console=ttyS0 console=logk0 earlyprintk=nologger loglevel=7 hsu_dma=7 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=blackbay emmc_ipanic.ipanic_part_number=1 androidboot.wakesrc=0B androidboot.mode=main\" > /sys/kernel/debug/osip/cmdline" 


