
rm -rf axPytime
mkdir axPytime

sshpass -p root scp root@192.168.0.2:/dev/shm/axPytime* ./axPytime/
sshpass -p root scp root@192.168.0.2: "rm -rf /dev/shm/axPytime* "


cd axPytime
cat axPytime* > all.txt
pytimechart all.txt
