
adb push ~/tools/wake.sh /data
#adb shell "/data/wake.sh &"
adb shell "echo 0 > /sys/kernel/debug/alarm-backoff/threshold"
adb shell "echo 0 > /sys/kernel/debug/suspend-backoff/threshold"

echo done

while true
do

ping 192.168.1.104 -c 2
sleep 2

done

