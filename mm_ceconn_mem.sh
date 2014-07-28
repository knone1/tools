

while true; do
	PID=`sshpass -p root ssh root@192.168.0.2 "pidof ceconn"`
	sshpass -p root ssh root@192.168.0.2 "cat /proc/$PID/status |grep kB"
	echo "------"
	sleep 1
done

