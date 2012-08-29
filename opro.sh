

PROJECT=~/project
 
cd $PROJECT

rm -rf /oprofile
adb pull /system/lib/opimport_pull_x86
chmod 777 ./opimport_pull_x86

cp ~/project/outp/axel_kernel/vmlinux .
adb push ./vmlinux /sdcard/

adb shell "killall -9 oprofiled"

KSRT=`adb shell "grep _stext /proc/kallsyms"|awk '{ print $1 }'`
KEND=`adb shell "grep _etext /proc/kallsyms"|awk '{ print $1 }'`
adb shell "opcontrol --quick --verbose --callgraph=5 --vmlinux=/sdcard/vmlinux --kernel-range=0x$KSRT,0x$KEND"
#adb shell "stop;wlx mpc 0;wlx scansuppress 1;wlx country XY; busybox ifconfig wlan0 192.168.1.2; busybox arp -s 192.168.1.1 00:11:22:33:44:55"
#adb shell "/data/iperf-static -c 192.168.1.1 -i 1 -u -b 100M -t 30" &
#perf2.sh -udp_down&
adb shell "opcontrol --start"
sleep 10
adb shell "opcontrol --status"
adb shell "opcontrol --stop"
adb shell "opcontrol --dump"
./opimport_pull_x86 -r ./oprofile/
mv ./vmlinux ./oprofile/

cd  oprofile
opreport --symbols --session-dir=. --image-path=.,/home/axelh/project/outp/symbols|head



