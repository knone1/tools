sudo echo ""

####################################################################################
INTERFACE=eth0
INJECT="/home/axelh/hexinject-1.4.1/hexinject/hexinject -p -i $INTERFACE"

#SOURCE MAC ADDRESS
SRC=080028710745

#LIST OF RANDOM DEST MAC TO USE
MAC1=a00bbaafea53
MAC2=ccf3a529654a
MAC3=080028f22b63
MAC4=ccf3a5296548
MAC5=98fe94011394

####################################################################################
#NBNS_IPv4_broadcast()
func1()
{
	DATA=$DST$SRC"08004500004e0228000080114626c0a83801c0a838ff00890089003ac228a17001100001000000000000204644454a4641434f454a454f46454546454d434f45444550454e4341434141410000200001"
}

#SSDP_IPv4_multicast()
func2()
{
	DATA=$DST$SRC"08004500009902c000000111052bc0a800c7effffffacdd1076c008575074d2d534541524348202a20485454502f312e310d0a486f73743a3233392e3235352e3235352e3235303a313930300d0a53543a75726e3a736368656d61732d75706e702d6f72673a6465766963653a4d6564696152656e64657265723a310d0a4d616e3a22737364703a646973636f766572220d0a4d583a330d0a0d0a431d713d"
}

#IGMP_IPv4_multicast()
func3()
{
	DATA=$DST$SRC"080046c000200000400001022173c0a82101e00000fb9404000016000904e00000fbba0f3e53"
}

#MDNS_IPv4_multicast()
func4()
{
	DATA=$DST$SRC"0800451c007603010000ff1115ebc0a800cbe00000fb14e914e90062bf2e0000000000010000000000000139013601360135013401310165016601660166013101620136016601610162013001300130013001300130013001300130013001300130013001380165016603697036046172706100000c0001794e66e0"
}

#DHCPv6_IPv6_multicast()
func5()
{
	DATA=$DST$SRC"86dd60000000005f1101fe80000000000000cddebfc598a09036ff02000000000000000000000001000202220223005ffd9f01396a360008000202bc0001000e0001000117a8e31a001fbc0e26310003000c0e001fbc000000000000000000270009000753522d582d50430010000e0000013700084d53465420352e300006000800180017001100274f56e031"
}

#MDNS_IPv6_multicast()
func6()
{
	DATA=$DST$SRC"86dd60000000006211fffe80000000000000baf6b1fffe145669ff0200000000000000000000000000fb14e914e90062a1aa0000000000010000000000000139013601360135013401310165016601660166013101620136016601610162013001300130013001300130013001300130013001300130013001380165016603697036046172706100000c0001c7732352"
}

get_random()
{
	RNUM=$((RANDOM%$2+$1))
}

main()
{
	echo "getting random mac... $1 $2"
	#get_random 1 5;RMAC=$RNUM;
	RMAC=$1
	case $RMAC in
		1) MAC=$MAC1;;
		2) MAC=$MAC2;;
		3) MAC=$MAC3;;
		4) MAC=$MAC4;;
		5) MAC=$MAC5;;
		*) MAC=$MAC1;;
	esac
	echo "Mac is "$MAC;
	SRC=$SRC
	DST=$MAC

	echo "Getting random function..."
	#get_random 1 6;RFUNC=$RNUM;
	RFUNC=$2
	case $RFUNC in
		1) func1;;
		2) func2;;
		3) func3;;
		4) func4;;
		5) func5;;
		6) func6;;
		*)
	esac
	echo "function is: $DATA"

	echo "Injecting data..."
	echo $DATA|sed 's/.\{2\}/& /g'|sudo $INJECT	
}

loop_main()
{
	while true; do
		for VAR2 in 1 2 3 4 5 6; do
			for VAR1 in 1 2 3 4 5; do
				main $VAR1 $VAR2 
			done
			echo "------------------------"
			sleep 10;
		done
	done
}
loop_main

