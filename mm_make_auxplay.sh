#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-devel-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-debuginfo-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm


cd /home/mmes/build

rm /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-*
cp -rf /home/mmes/GITS/multimedia/dist/libauxin-player/src/src/* ./build/libauxin-player-1.6/BUILD/libauxin-player-1.6/src/


make -C build -j8 libauxin-player.clean
make -C build -j8 libauxin-player


ls
sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"
sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-* root@192.168.0.2:/tmp
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /tmp/libauxin-player-1.6*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /tmp/libauxin-player-devel*.rpm|cpio -ivd;sync"
#sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /tmp/libauxin-player-debuginfo*.rpm|cpio -ivd;sync"

