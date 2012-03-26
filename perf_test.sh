TEST_TIME=25

# CLIENT

client_udp_down()
{
	# UDP DOWN
	echo "client_udp_down"
	adb shell "/data/iperf-static -s -i 5 -u > /data/iperf_client.txt" &
}

client_udp_up()
{
	echo "client udp up"
	# UDP UP 
	adb shell "/data/iperf-static -u -c 192.168.1.100 -b 55M -t 5000 > /data/iperf_client.txt" &
}

client_tcp_up()
{
	# TCP UP 
	 echo "client_tcp_up"
	adb shell "/data/iperf-static -c 192.168.1.100 -t 5000 -i 5 -w 64k > /data/iperf_client.txt" &
}

client_tcp_down()
{
	# TCO DOWN
	echo "client_tcp_down"
	adb shell "/data/iperf-static -s -i 5 > /data/iperf_client.txt" &
}

server_udp_down()
{
	echo "server_udp_down"
	iperf -u -c 192.168.1.101 -b 55M -t 5000 > ~/iperf_server.txt &
}

server_udp_up()
{
	echo "server udp up"
	iperf -s -i 5 -u > ~/iperf_server.txt &
}

server_tcp_down()
{
	echo "server_tcp_down"
	iperf -c 192.168.1.101 -t 5000 -i 5 -w 64k > ~/iperf_server.txt &
}

server_tcp_up()
{
	echo "server_tcp_up"
	iperf -s -i 5 > ~/iperf_server.txt &
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
	adb pull /data/iperf_client.txt ~/
	echo "**************** iperf_client">> $FILE
	cat ~/iperf_client.txt >> $FILE
	echo  echo "**************** iperf_server" >> $FILE
	cat ~/iperf_server.txt >> $FILE
	rm ~/iperf_client.txt
	rm ~/iperf_server.txt
	
}


run(){
FILE=~/iperf$1.txt
echo "####################################" > $FILE
echo $1>> $FILE
echo "####################################">> $FILE
case $1 in
	-udp_up)
		server_udp_up
		sleep 1;
		client_udp_up
		sleep $TEST_TIME;
		clean;
		;;

	-udp_down)
		client_udp_down
		sleep 1;
		server_udp_down
		sleep $TEST_TIME;
		clean;
		;;
	-tcp_up)
		server_tcp_up
		sleep 1;
		client_tcp_up
		sleep $TEST_TIME;
		clean;
		;;

	-tcp_down)
		client_tcp_down
		sleep 1;
		server_tcp_down
		sleep $TEST_TIME;
		clean;
		;;

	-h)
		usage
		;;
	*)	usage
		;;

esac
}

case $1 in
	-all)
		rm ~/iperf*
		run -udp_up
		run -udp_down
		run -tcp_up
		run -tcp_down
		cat ~/iperf* > ~/result.txt
		;;
	*)
		run $1
esac









