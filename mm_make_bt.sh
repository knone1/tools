
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-bt-0.3-1_WR3.0.2ax.armv6jel_vfp-eb0eb46.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-bt-debuginfo-0.3-1_WR3.0.2ax.armv6jel_vfp-eb0eb46.rpm


cd ~/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-bt-*


cp /home/mmes/GITS/multimedia/dist/vmost-auxin-bt/src/src/* ./build/vmost-auxin-bt-0.3/src/

#cp -rf /home/mmes/GITS/multimedia/dist/libauxin-player/src/src/* ./build/libauxin-player-1.6/BUILD/libauxin-player-1.6/src/



make -C build vmost-auxin-bt.clean
make -C build vmost-auxin-bt

sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"

sshpass -p root scp  /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-bt* root@192.168.0.2:/

sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-auxin-bt-0*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-auxin-bt-debuginfo-*.rpm|cpio -ivd;sync"




