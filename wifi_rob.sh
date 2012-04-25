wifi(){
	adb shell am start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings
	adb shell input keyevent 19 
	adb shell input keyevent 66
}

bt(){
	adb shell am start -a android.intent.action.MAIN -n com.android.settings/.bluetooth.BluetoothSettings
	adb shell input keyevent 19
	adb shell input keyevent 66
}

nfc(){

	adb shell am start -a android.intent.action.MAIN -n com.android.settings/.Settings
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 66
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 66
	adb shell input keyevent 3
}

flood(){
sudo ping 10.251.35.176  -f &
sleep 10
sudo killall -9 ping
}

perf(){
/home/axelh/tools/perf_test.sh -all
}

thet(){
	adb shell am start -a android.intent.action.MAIN -n com.android.settings/.Settings
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 66
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 20
	adb shell input keyevent 20
	adb shell input keyevent 66
	adb shell input keyevent 19
	adb shell input keyevent 19
	adb shell input keyevent 20
	adb shell input keyevent 66
	adb shell input keyevent 3
}
while true; do
	sudo echo ""
	phy 0 off
	sleep 4

	wifi
	sleep 5

	adb shell input keyevent 3
	sleep 5

	wifi
	sleep 1
	adb shell input keyevent 26

	phy 0 on
	sleep 30
done;


