
sshpass -p root ssh root@192.168.0.2 "pkill strace"
PID=`sshpass -p root ssh root@192.168.0.2 "ps|grep ceconn|head -1" |awk '{print $1}'`

sshpass -p root scp ~/tools/strace root@192.168.0.2:/tmp

sshpass -p root ssh root@192.168.0.2 "/tmp/strace -x -f -s 500 -e write=25 -e read=20 -e write,read,open,close  -p $PID -o /tmp/trace.txt "&
sleep 20

sshpass -p root ssh root@192.168.0.2 "pkill strace"
sshpass -p root scp  root@192.168.0.2:/tmp/trace.txt .
