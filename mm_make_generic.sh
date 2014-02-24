
cd ~/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-generic*

cp /home/mmes/GITS/multimedia/dist/libauxin-generic/src/src/auxin-perf/CPerformanceHit.h ./build/libauxin-generic-1.6/BUILD/libauxin-generic-1.6/src/auxin-perf/CPerformanceHit.h
cp /home/mmes/GITS/multimedia/dist/libauxin-generic/src/src/auxin-perf/CPerformanceHit.cpp ./build/libauxin-generic-1.6/BUILD/libauxin-generic-1.6/src/auxin-perf/CPerformanceHit.cpp

cp /home/mmes/GITS/multimedia/dist/vmost-mmp/src/src/mmp/CSimMultiMediaPlayer.h ./build/vmost-mmp-0.5/src/mmp/CSimMultiMediaPlayer.h


make -C build libauxin-generic.clean
make -C build libauxin-generic



sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"
sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-generic-* root@192.168.0.2:/

sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./libauxin-generic-1.6-1*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./libauxin-generic-debuginfo-*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./libauxin-generic-devel-*.rpm|cpio -ivd;sync"



