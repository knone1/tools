TEST_TIME=25
DUT_IP=192.168.1.100
PC_IP=192.168.1.24
DIR=$PWD
adb push ~/tools/iperf-static /data

sudo echo ""
# CLIENT

goto_off()
{
	adb shell input keyevent 4
	adb shell input keyevent 4
	adb shell input keyevent 4
	adb shell input keyevent 21
	adb shell input keyevent 22
	adb shell input keyevent 23
	sleep 2
	adb shell input keyevent 20
}

toggle_off()
{
	adb shell input keyevent 19
	adb shell input keyevent 66
	adb shell input keyevent 20


}
clean2()
{
	goto_off;
	adb shell input keyevent 20

	for i in `seq 1 40`;
	do
		adb shell input keyevent 22
	done
	for i in `seq 1 40`;
	do
		adb shell input keyevent 67
	done
	toggle_off;
	goto_off;
	adb shell input keyevent 20

	
}

dut_udp_down2()
{
	echo "dut_udp_down2"
	adb shell input text "-s"
	adb shell input keyevent 62
	adb shell input text "-u"
	
	toggle_off
}

dut_udp_up2()
{
	echo "dut_udp_up2"
	adb shell input text "-u";	adb shell input keyevent 62
	adb shell input text "-c";	adb shell input keyevent 62
	adb shell input text "$PC_IP";adb shell input keyevent 62
	adb shell input text "-b";	adb shell input keyevent 62
	adb shell input text "200M";	adb shell input keyevent 62
	adb shell input text "-t" ;	adb shell input keyevent 62
	adb shell input text "10" ;	adb shell input keyevent 62

	toggle_off
	#adb shell "/data/iperf-static -u -c $PC_IP -b 200M -t 10 > /data/iperf_client.txt" &
}

dut_tcp_up2()
{
	# TCP UP 
	echo "dut_tcp_up2"
	adb shell input text "-c";	adb shell input keyevent 62
	adb shell input text "$PC_IP";adb shell input keyevent 62
	adb shell input text "-t" ;	adb shell input keyevent 62
	adb shell input text "10" ;	adb shell input keyevent 62
	adb shell input text "-i" ;     adb shell input keyevent 62
	adb shell input text "5" ;     adb shell input keyevent 62
	adb shell input text "-w" ;     adb shell input keyevent 62
	adb shell input text "64k" ;     adb shell input keyevent 62

	toggle_off

#	adb shell "/data/iperf-static -c $PC_IP -t 10 -i 5 -w 64k > /data/iperf_client.txt" &
}

dut_tcp_down2()
{
	# TCO DOWN
	echo "dut_tcp_down2"
	adb shell input text "-s"

	toggle_off
#	adb shell "/data/iperf-static -s > /data/iperf_client.txt" &
}


dut_udp_down()
{
	# UDP DOWN
	echo "client_udp_down"
	adb shell "/data/iperf-static -s -u > /data/iperf_client.txt" &
}

dut_udp_up()
{
	echo "client udp up"
	# UDP UP 
	adb shell "/data/iperf-static -u -c $PC_IP -b 200M -t 10 > /data/iperf_client.txt" &
}

dut_tcp_up()
{
	# TCP UP 
	 echo "client_tcp_up"
	adb shell "/data/iperf-static -c $PC_IP -t 10 -i 5 -w 64k > /data/iperf_client.txt" &
}

dut_tcp_down()
{
	# TCO DOWN
	echo "client_tcp_down"
	adb shell "/data/iperf-static -s > /data/iperf_client.txt" &
}

pc_udp_down()
{
	echo "server_udp_down"
	echo "iperf -u -c $DUT_IP -b 200M -t 10 -i 1"
	iperf -u -c $DUT_IP -b 200M -t 10 -i 1 > $DIR/iperf_server.txt &
}

pc_udp_up()
{
	echo "server udp up"
	iperf -s -i 5 -u > $DIR/iperf_server.txt &
}

pc_tcp_down()
{
	echo "server_tcp_down"
	iperf -c $DUT_IP -t 10 -i 5 -w 64k > $DIR/iperf_server.txt &
}

pc_tcp_up()
{
	echo "server_tcp_up"
	iperf -s -i 5 > $DIR/iperf_server.txt &
}
usage()
{
	echo "usage:
-udp_up
-udp_down
-tpp_up
-tcp_down
"

}

clean()
{
	killall -9 adb
	killall -9 iperf
	sudo adb kill-server
	sudo adb start-server	
	adb pull /data/iperf_client.txt $DIR
	echo "**************** iperf_client">> $FILE
	cat $DIR/iperf_client.txt >> $FILE
	echo  echo "**************** iperf_server" >> $FILE
	cat $DIR/iperf_server.txt >> $FILE
	rm $DIR/iperf_client.txt
	rm $DIR/iperf_server.txt
}

usb_on(){
#phy 0 off
#sleep 3
echo 
}

usb_off(){
#phy 0 on
echo
}

run(){
FILE=$DIR/iperf$1.txt
echo "####################################" > $FILE
echo $1>> $FILE
echo "####################################">> $FILE
case $1 in
	-udp_up)
		pc_udp_up
		sleep 1;
		dut_udp_up;
		usb_off;
		sleep $TEST_TIME;
		usb_on;
		clean;
		;;

	-udp_up2)
		dut_udp_up2;
		adb shell input keyevent 26;
		;;
	-udp_down2)
		dut_udp_down2;
		adb shell input keyevent 26;
		;;
	-udp_down)
		dut_udp_down;
		sleep 3;
		pc_udp_down
		usb_off;
		sleep $TEST_TIME;
		usb_on;
		clean;
		echo "sssss"
		cat $DIR/iperf$1.txt |tail -2|head -1|awk 'BEGIN{FS=" "}{printf $7"\n"}'
		;;
	-tcp_up)
		pc_tcp_up
		sleep 1;
		dut_tcp_up;
		usb_off;
		sleep $TEST_TIME;
		usb_on;
		clean;
		;;
	-tcp_up2)
		dut_tcp_up;
		adb shell input keyevent 26;
		;;
	-tcp_down)
		dut_tcp_down;
		sleep 3;
		pc_tcp_down;
		usb_off;
		sleep $TEST_TIME;
		usb_on;
		clean;
		;;
	

	-h)
		usage
		;;
	*)	usage
		;;

esac

cat $DIR/iperf$1.txt

}
case $1 in
	-all)
		rm $DIR/iperf*
		run -udp_up
		run -udp_down
		run -tcp_up
		run -tcp_down
		cat $DIR/iperf* > $DIR/result.txt
		;;
	*)
		run $1
esac









