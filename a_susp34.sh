while true;do 

cat /sys/kernel/debug/wakeup_sources | awk '{print $1 " " $6}' |grep -v " 0" |grep -v active; 
echo "______";
sleep 1;

done;


