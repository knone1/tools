

TIME="30"
DUT_IP="192.168.2.117"
PC_IP="192.168.2.24"
BAN="200M"
WINDOW="64k"
STEP="1"
#IPERF_DUT="/data/data/com.magicandroidapps.iperf/bin/iperf"
IPERF_DUT="/data/iperf-static"

IPERF_PC="iperf"


cmd_set()
{
	UDP_S="-s -i $STEP -u"
	TCP_S="-s"
	UDP_C="-c $S_IP -b $BAN -t $TIME -u"
	TCP_C="-c $S_IP -t $TIME -w $WINDOW -i $STEP"
}


#DUT IPERF COMMADS
dut_udp_s()
{
	adb shell "$IPERF_DUT $UDP_S" &
	sleep 1;
}
dut_udp_c()
{
	adb shell "$IPERF_DUT $UDP_C"
}
dut_tcp_s()
{
	
	adb shell "$IPERF_DUT $TCP_S" &
	sleep 1;
}
dut_tcp_c()
{
	adb shell "$IPERF_DUT $TCP_C"
}


#PC IPERF COMMANDS
pc_udp_s()
{
	$IPERF_PC $UDP_S &
	sleep 1;
}
pc_udp_c()
{
	$IPERF_PC $UDP_C
}
pc_tcp_s()
{
	
	$IPERF_PC $TCP_S &
	sleep 1;
}
pc_tcp_c()
{
	$IPERF_PC $TCP_C
}


killall -9 adb
killall -9 iperf

case $1 in
	-udp_rx)
		S_IP=$DUT_IP;
		cmd_set;
		dut_udp_s;
		pc_udp_c;;
	-udp_tx)
		S_IP=$PC_IP;
		cmd_set;
		pc_udp_s;
		dut_udp_c;;
	-tcp_rx)
		S_IP=$DUT_IP;
		cmd_set;
		dut_tcp_s;
		pc_tcp_c;;
	-tcp_tx)
		S_IP=$PC_IP;
		cmd_set;
		pc_tcp_s;
		dut_tcp_c;;

esac

echo "done"


