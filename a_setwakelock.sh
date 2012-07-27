aaa.sh uo
sleep 2
if [ $1 == 's' ]; then
	echo "WAKELOCK SET"
	adb shell "echo 1 >/sys/power/wake_lock"
else
	echo "WAKELOCK UNSET"
	adb shell "echo 1 > /sys/power/wake_unlock"
fi
echo "CURRENT USER WAKLOCKS:"
adb shell "cat /sys/power/wake_lock"
adb shell "echo mem > /sys/power/state"

aaa.sh uf

#adb shell "echo 1 >/sys/power/wake_lock"
#adb shell "echo 1 > /sys/power/wake_unlock"

