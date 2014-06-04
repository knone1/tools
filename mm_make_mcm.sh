#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-devel-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-debuginfo-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm

if [ -z "$1" ]; then

cd /home/mmes/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-mcm-*
cp -rf /home/mmes/GITS/multimedia/dist/libauxin-mcm/src/src/* ./build/libauxin-mcm-1.6/BUILD/libauxin-mcm-1.6/src/
make -C build mtp-utils.distclean
make -C build tracker.distclean
make -C build gdk-pixbuf.distclean
make -C build libauxin-mcm.distclean
make -C build libauxin-mcm

fi

cd /home/mmes/build
sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt;"
sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-mcm-1.6* root@192.168.0.2:/dev/shm
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /dev/shm/libauxin-mcm-1.6*.rpm|cpio -ivd;sync"
#sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /dev/shm/libauxin-mcm-devel*.rpm|cpio -ivd;sync"
#sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /tmp/libauxin-player-debuginfo*.rpm|cpio -ivd;sync"


