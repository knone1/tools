sshpass -p root ssh root@192.168.0.2 "ls /dev/shm/ax*"
rm axdata*

sshpass -p root scp root@192.168.0.2:/dev/shm/ax* .
cat axdata* > axf.txt
#cat axf.txt|tail -n +30 > axf2.txt
#rm axf.txt
#pytimechart axf2.txt&



