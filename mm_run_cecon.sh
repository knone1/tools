

PID=`sshpass -p root ssh root@192.168.0.2 "ps|grep ceconn|head -1" |awk '{print $1}'`

sshpass -p root ssh root@192.168.0.2 "kill -9 $PID"
mms.sh
