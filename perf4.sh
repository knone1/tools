
####################
#    SETTINGS
####################
DUT_IP=192.168.1.102
PC_IP=192.168.2.24
ANDROID_IPERF=~/tools/iperf-static


####################
#   VARIABLES
####################
DIR=$PWD
TEST="NONE"
W=64k
PT=10
TEST_TIME=15
M=200

usage()
{
echo "usage:
perf2.sh -udp_up
perf2.sh -udp_down
perf2.sh -tpp_up
perf2.sh -tcp_down
perf2.sh -all

inside the script file you have to set the 
DUT_IP PC_IP ANDROID_IPERF
to the right values, where:

DUT_IP: ip address of the device
PC_IP: ip address of the pc
ANDROID_IPERF: path of the static compiled iperf binary

results will be stored on the running dir
in the file iperf_results.txt. the output
of the server and client for each test will be
on the file iperf-*. for example:
	iperf-udp_down.txt
"

}

print()
{
        echo "#######################################################"
        echo $1
        echo "#######################################################"
}

dut_udp_down_s()
{
	echo  "dut_udp_down /data/iperf-static -s -u -i 1"
	adb shell "/data/iperf-static -s -u > /data/iperf_server.txt" &
}

pc_udp_down_c()
{
	echo "pc_udp_down iperf -u -c $DUT_IP -b $M"M" -t $PT -i 1"
	iperf -u -c $DUT_IP -b $M"M" -t $PT -i 1 > $DIR/iperf_client.txt
}

dut_udp_up_c()
{
	echo "dut_udp_up /data/iperf-static -u -c $PC_IP -b $M"M" -t $PT"
	adb shell "/data/iperf-static -u -c $PC_IP -b $M"M" -t $PT > /data/iperf_client.txt"
}

dut_tcp_up()
{
	echo "dut_tcp_up /data/iperf-static -c $PC_IP -t $PT -i 1 -w $W"
	adb shell "/data/iperf-static -c $PC_IP -t $PT -i 1 -w $W > /data/iperf_client.txt" &
}

dut_tcp_down()
{
	echo "dut_tcp_down /data/iperf-static -s"
	adb shell "/data/iperf-static -s > /data/iperf_server.txt" &
}


pc_udp_up_s()
{
	echo "pc_udp_up iperf -s -u -i 1"
	iperf -s -u > $DIR/iperf_server.txt &
}

pc_tcp_down()
{
	echo "pc_tcp_down iperf -c $DUT_IP -t $PT -i 1 -w $W"
	iperf -c $DUT_IP -t $PT -i 1 -w $W > $DIR/iperf_client.txt &
}

pc_tcp_up()
{
	echo "pc_tcp_up iperf -s"
	iperf -s > $DIR/iperf_server.txt &
}

clean()
{
	killall -9 adb 2>/dev/null
	killall -9 iperf 2>/dev/null
	adb kill-server 2>/dev/null
	adb start-server 2>/dev/null
	adb pull /data/iperf_client.txt 2>/dev/null
	adb pull /data/iperf_server.txt 2>/dev/null	
	adb shell "rm /data/iperf_*"

	print "iperf_client">> $FILE
	cat $DIR/iperf_client.txt >> $FILE
	rm $DIR/iperf_client.txt

	print "iperf_server" >> $FILE
	cat $DIR/iperf_server.txt >> $FILE
	RESULT=`cat $DIR/iperf_server.txt |grep Mbits/sec|tail -1| awk 'BEGIN{FS="Mbits/sec"}{printf $1"\n"}'|awk 'BEGIN{FS=" "}{printf $NF"\n"}'`
	rm $DIR/iperf_server.txt

	echo  "$TEST $RESULT"
	echo  "AXRES $TEST $RESULT" >>$DIR/iperf_result.txt
}

run()
{

	FILE=$DIR/iperf$1.txt
	case $1 in
	-udp_up)
		TEST="UDP_UP"
		print $TEST
		pc_udp_up_s
		sleep 3;
		dut_udp_up_c;
		clean;
		;;

	-udp_down)
		TEST="UDP_DOWN"
		print $TEST
		dut_udp_down_s;
		sleep 3;
		pc_udp_down_c;
		clean;
		;;
	-tcp_up)
		TEST="TCP_UP"
		print $TEST
		pc_tcp_up
		sleep 3;
		dut_tcp_up;
		echo "sleep for $TEST_TIME"
		sleep $TEST_TIME;
		clean;
		;;
	-tcp_down)
		TEST="TCP_DOWN"
		print $TEST
		dut_tcp_down;
		sleep 3;
		pc_tcp_down;
		echo "sleep for $TEST_TIME"
		sleep $TEST_TIME;
		clean;
		;;
	
	*)	usage
		;;

	esac
}

insmod_4c()
{

echo "insmod 2g"
adb shell "rmmod bcmdhd"
sleep 2
adb shell "insmod /lib/modules/bcmdhd_4334.ko firmware_path=/system/etc/firmware/fw_bcmdhd_4334.bin nvram_path=/data/bcmdhd_new_4c.cal"
sleep 2
adb shell "ifconfig wlan0 up 192.168.2.15"
sleep 2
echo "insmod done."

}

insmod_30()
{

echo "insmod 2g"
adb shell "rmmod bcmdhd"
sleep 2
adb shell "insmod /lib/modules/bcmdhd_4334.ko firmware_path=/system/etc/firmware/fw_bcmdhd_4334.bin nvram_path=/data/bcmdhd_new_30.cal"
#adb shell "insmod /lib/modules/bcmdhd_4335.ko firmware_path=/system/etc/firmware/fw_bcmdhd_4335.bin nvram_path=/system/etc/wifi/bcmdhd_4335.cal"

sleep 2
adb shell "ifconfig wlan0 up 192.168.2.15"
sleep 2
echo "insmod done."

}

join_2G()
{
	adb shell "/data/wlx join axel_2G_20"
	sleep 5;
}

join_5G()
{
	adb shell "/data/wlx disassoc"
	sleep 2;
	adb shell "/data/wlx join axel_5G_40"
	sleep 5;
	
}

setup()
{
	sudo echo ""
	print "SETUP"


	echo "check if android iperf exists..."
	if [ -e $ANDROID_IPERF ]; then
		echo "android iperf...OK"
	else
		echo "android iperf...FAIL"
		exit
	fi 

	echo "check pc ip..."
	ifconfig eth0 > $DIR/ifconfig.txt
	PCIP=`cat $DIR/ifconfig.txt |grep "inet addr"|tail -1|awk 'BEGIN{FS=":"}{printf $2"\n"}'|awk 'BEGIN{FS=" "}{printf $1"\n"}'`
	echo "Pc ip... $PCIP"
	if [ "$PC_IP" = "$PCIP" ];then
		echo "Pc ip... OK"
	else
		echo "Pc ip... fail PC is set to $PC_IP and  ip is $PCIP"
		exit
	fi

	echo "Finding decice..."
	ISPRESENT=`adb devices|grep Medfield`
	if [ -n "$ISPRESENT" ];then
		echo "Device... FOUND"
	else
		echo "Device... NOT FOUND"
		exit
	fi

	echo "Get device ip..."
	adb shell "busybox ifconfig wlan0 > /data/ifconfig.txt"
	adb pull /data/ifconfig.txt $DIR  2>/dev/null 
	DEVIP=`cat $DIR/ifconfig.txt |grep "inet addr"|tail -1|awk 'BEGIN{FS=":"}{printf $2"\n"}'|awk 'BEGIN{FS=" "}{printf $1"\n"}'`
	echo "Device ip... $DEVIP"
	DUT_IP=$DEVIP
	if [ "$DUT_IP" = "$DEVIP" ];then
		echo "Device ip... OK"
	else
		echo "Device ip... fail DUT is $DUT_IP dev is $DEVIP"
		exit
	fi

	echo "Pinging $DUT_IP"
	FLAG="";

	while [ -z "$FLAG" ]; do

	ISPINGOK=`ping -c 1 $DUT_IP |grep time=`
	if [ -n "$ISPINGOK" ];then
		echo "Ping... OK"
		FLAG=1
	else
		echo "Ping... FAIL"
	fi

	done

	echo "push iperf..."
	adb push $ANDROID_IPERF /data 2>/dev/null

	echo cleaning 
	rm  $DIR/iperf_* 2>/dev/null
	adb shell "rm /data/iperf_*" 2>/dev/null

	echo "getting RSSI"
	adb shell "/data/wlx status >/data/status.txt"
	adb pull /data/status.txt $DIR  2>/dev/null
	RSSI=`cat $DIR/status.txt|grep RSSI|awk '{print $4}'`
	echo "RSSI=$RSSI"

	echo setting perf to max
	adb shell "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
	adb shell "echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor"
	adb shell "/data/wlx PM 0"
	adb shell "/data/wlx scansuppress 1"
	adb shell "/data/wlx country XY"
	
	echo "Setup OK!"
	echo ""	
}


###############################################################################


if [ -z "$1" ]; then
        usage
        exit
fi


test_R(){
setup;
case $1 in
	-all)
		run -udp_up
		run -udp_down
#		run -tcp_up
#		run -tcp_down
		print "TEST DONE"
		cat $DIR/iperf_result.txt
		;;
	*)
		run $1
esac
}

insmod_4c;
join_2G;
test_R $1;
RES2G4C=`cat $DIR/iperf_result.txt`

insmod_4c;
join_5G;
test_R $1;
RES5G4C=`cat $DIR/iperf_result.txt`

insmod_30;
join_2G;
test_R $1;
RES2G30=`cat $DIR/iperf_result.txt`

insmod_30;
join_5G;
test_R $1;
RES5G30=`cat $DIR/iperf_result.txt`


echo "RES2G4C"
echo "$RES2G4C"
echo "RES5G4C"
echo "$RES5G4C"
echo "RES2G30"
echo "$RES2G30"
echo "RES5G30"
echo "$RES5G30"


