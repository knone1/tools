PID=`sshpass -p root ssh root@192.168.0.2 "pidof ceconn"`

while true; do
	sshpass -p root ssh root@192.168.0.2 "ps -T|grep ceconn"
	sleep 1
done

