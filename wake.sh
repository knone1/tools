while true;do cat /proc/wakelocks | awk '{print $1 " " $5}' |grep -v " 0" |grep -v active >/dev/ttyS0; dumpsys power|grep WAKE >/dev/ttyS0;echo "______">/dev/ttyS0;sleep 1;done;
