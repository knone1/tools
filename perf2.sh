
####################
#    SETTINGS
####################
DUT_IP=192.168.1.100
PC_IP=192.168.1.24
ANDROID_IPERF=~/tools/iperf-static


####################
#   VARIABLES
####################
DIR=$PWD
TEST="NONE"
W=64k
PT=30
TEST_TIME=35
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

dut_udp_down()
{
	echo  "dut_udp_down /data/iperf-static -s -u"
	adb shell "/data/iperf-static -s -u > /data/iperf_server.txt" &
}

pc_udp_down()
{
	echo "pc_udp_down iperf -u -c $DUT_IP -b $M"M" -t $PT -i 1"
	iperf -u -c $DUT_IP -b $M"M" -t $PT -i 1 > $DIR/iperf_client.txt &
}

dut_udp_up()
{
	echo "dut_udp_up /data/iperf-static -u -c $PC_IP -b $M"M" -t 10"
	adb shell "/data/iperf-static -u -c $PC_IP -b $M"M" -t $PT > /data/iperf_client.txt" &
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


pc_udp_up()
{
	echo "pc_udp_up iperf -s -u"
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
		pc_udp_up
		sleep 3;
		dut_udp_up;
		echo "sleep for $TEST_TIME"
		sleep $TEST_TIME;
		clean;
		;;

	-udp_down)
		TEST="UDP_DOWN"
		print $TEST
		dut_udp_down;
		sleep 3;
		pc_udp_down
		echo "sleep for $TEST_TIME"
		sleep $TEST_TIME;	
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
	ISPINGOK=`ping -c 1 $DUT_IP |grep time=`
	if [ -n "$ISPINGOK" ];then
		echo "Ping... OK"
	else
		echo "Ping... FAIL"
		exit
	fi

	echo "push iperf..."
	adb push $ANDROID_IPERF /data 2>/dev/null

	echo cleaning 
	rm  $DIR/iperf_* 2>/dev/null
	adb shell "rm /data/iperf_*" 2>/dev/null
	
	echo "Setup OK!"
	echo ""	
}


###############################################################################


if [ -z "$1" ]; then
        usage
        exit
fi

setup;
case $1 in
	-all)
		run -udp_up
		run -udp_down
		run -tcp_up
		run -tcp_down
		print "TEST DONE"
		cat $DIR/iperf_result.txt
		;;
	*)
		run $1
esac









