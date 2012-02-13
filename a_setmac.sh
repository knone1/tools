adb shell "
	busybox ifconfig wlan0 down;
	busybox ifconfig wlan0 hw ether 08:00:28:55:52:FE;
	busybox ifconfig wlan0 up;
	
	"

