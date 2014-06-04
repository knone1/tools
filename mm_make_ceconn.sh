#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-D_38.2-1_WR3.0.2ax.armv6jel_vfp-2f1e05c.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-devel-D_38.2-1_WR3.0.2ax.armv6jel_vfp-2f1e05c.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-debuginfo-D_38.2-1_WR3.0.2ax.armv6jel_vfp-2f1e05c.rpm

#/home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-D_38.2-1_WR3.0.2ax.armv6jel_vfp-2f1e05c.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libmtp-1.1.6-1_WR3.0.2ax.armv6jel_vfp-0777c0e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libmtp-devel-1.1.6-1_WR3.0.2ax.armv6jel_vfp-0777c0e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libmtp-debuginfo-1.1.6-1_WR3.0.2ax.armv6jel_vfp-0777c0e.rpm




if [ -z "$1" ]; then

cd /home/mmes/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-*

cp -rf /home/mmes/GITS/ceconn/dist/ceconn/src/ /home/mmes/build/build/ceconn-D_38.2/BUILD/ceconn-D_38.2/



make -C build  libmtp.distclean
make -C build  ceconn.distclean
make -C build  ceconn

fi

FILENAME=`ls /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn-D_38.2-1*|awk 'BEGIN{FS="/"}{print $8}'`
cd /home/mmes/build
sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt;"
 
echo "ddd /home/mmes/build/export/RPMS/armv6jel_vfp/$FILENAME"
cp "/home/mmes/build/export/RPMS/armv6jel_vfp/$FILENAME" "/home/mmes/build/export/RPMS/armv6jel_vfp/ceconn.rpm"


sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/ceconn.rpm root@192.168.0.2:/var/ceconn.rpm
sshpass -p root scp /home/mmes/VMSHARE/IAP/installceconnandroid.sh  root@192.168.0.2:/opt/ceconn/bin

sshpass -p root ssh root@192.168.0.2 "/opt/ceconn/bin/installceconnandroid.sh /var/ceconn.rpm"

sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/libmtp-* root@192.168.0.2:/dev/shm
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /dev/shm/libmtp-*.rpm|cpio -ivd;sync"
sync
#sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /tmp/libauxin-player-debuginfo*.rpm|cpio -ivd;sync"
PID=`sshpass -p root ssh root@192.168.0.2 "ps|grep ceconn|grep -v sh|head -1" |awk '{print $1}'`
sshpass -p root ssh root@192.168.0.2 "kill -9 $PID"
#sshpass -p root ssh root@192.168.0.2 "/opt/ceconn/bin/ceconn"




