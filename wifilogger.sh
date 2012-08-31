#!/system/bin/sh

run_stop() {
	rm /data/logs_wifi/start
	exit 0;
}

run_start() {
	touch /data/logs_wifi/start
	exit 0 ;
}

run_unload(){

	if [ -e /data/logs_wifi/start ]; then
		echo "SCRIPT is STARTED run stop first"		
		exit 1
	fi
	rm /data/logs_wifi/loaded
	killall -9 b.sh
	exit 0;
}

run_load() {
echo 0 > /sys/module/wl12xx/parameters/debug_level
echo 4 > /proc/sys/kernel/printk
echo 0 > /sys/module/wakelock/parameters/debug_mask

STARTED=0
INTKILLED=0
COUNT=0

if [ ! -e /data/logs_wifi ]; then
	mkdir /data/logs_wifi
fi

if [ -e /data/logs_wifi/loaded ]; then
	echo "SCRIPT is already LOADED"
	exit 1
else
	touch /data/logs_wifi/loaded
fi

if [ ! -e /system/bin/tcpdump ]; then
	echo "TCP dump not found in /system/bin/tcpdump"
fi


while true; do
if [ -e /data/logs_wifi/start ]; then
	DATE=`date`
	if [ $STARTED -eq 0 ]; then
		echo "##################   START WIFI LOG" >>/data/logs_wifi/log.txt
		echo 0x2DA0 > /sys/module/wl12xx/parameters/debug_level	
		echo 8 > /proc/sys/kernel/printk
		cat /proc/kmsg>>/data/logs_wifi/log.txt&

		if [ -e /system/bin/tcpdump ]; then 			
			/system/bin/tcpdump -i wlan0>>/data/logs_wifi/log.txt&
		fi
	fi
	
	echo "$DATE ------------------------" >>/data/logs_wifi/log.txt
	cat /proc/wakelocks | awk '{print $1 " " $5}' |grep -v " 0" |grep -v active>>/data/logs_wifi/log.txt

	if [ $COUNT -eq 30 ]; then
		WLANOK=`busybox ifconfig wlan0|grep UP`
		echo "check"
		echo $WLANOK
		COUNT=0
		if [ -z $WLANOK ]; then
			if [ $INTKILLED -eq 0 ]; then
				echo "INTERFACE DOWN"
				echo "################## INTERFACE DOWN " >>/data/logs_wifi/log.txt
				killall -9 tcpdump
				INTKILLED=1
			fi
		else
			if [ $INTKILLED -eq 1 ]; then
				echo "INTERFACE UP"
				echo "################## INTERFACE BACK UP" >>/data/logs_wifi/log.txt
				if [ -e /system/bin/tcpdump ]; then
					/system/bin/tcpdump>>/data/logs_wifi/log.txt&
				fi
				INTKILLED=0
			fi
		fi
	fi

	COUNT=`expr $COUNT + 1` 
	STARTED=1	
else
	if [ $STARTED -eq 1 ]; then
		echo "##################   STOP WIFI LOG" >>/data/logs_wifi/log.txt
		echo 0 > /sys/module/wl12xx/parameters/debug_level
		echo 4 > /proc/sys/kernel/printk

		killall -9 tcpdump
		killall -9 cat
	fi
	STARTED=0
fi

sleep 1;
done
}

usage()
{
	echo " 
	Wifi logger script
	------------------
	This scrip will increment the wifi driver log level
	and start /system/bin/tcpdump. The infromation will
	be saved in /data/logs_wifi/log.txt

	the script is a deamon that should be first loaded:
		#nohup /data/b.sh load &

	once loaded it can be start and stop logging:
		#/data/b.sh start
	or
		#/data/b.sh stop
	
	once done logging, you should stop and unload
		#/data/b.sh stop
		#/data/b.sh unload

"
}

case "$1" in
	"start") run_start;;
	"stop")  run_stop;;
	"load")  run_load;;
	"unload") run_unload;;
	*)usage;;
esac


