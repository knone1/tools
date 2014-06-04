

while true; do
	sshpass -p root ssh root@192.168.0.2 "ls -l /dev/shm/ax*";
	sleep 1;
done