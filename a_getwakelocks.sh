adb shell "dumpsys power;cat /proc/wakelocks | awk '{print $1 " " $5}' |grep -v " 0" |grep -v active"


