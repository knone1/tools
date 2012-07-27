adb shell "dumpsys power|grep WAKE"
adb shell "cat /proc/wakelocks" |awk '{print $1 " " $5}' |grep -v " 0" |grep -v active


