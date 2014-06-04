#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-devel-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-debuginfo-1.6-1_WR3.0.2ax.armv6jel_vfp-2e4031e.rpm

NAME=$1
FILE=$2

if [ -z "$1" ]; then

cd /home/mmes/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/libauxin-player-*
cp -rf /home/mmes/GITS/multimedia/dist/libauxin-player/src/src/* ./build/libauxin-player-1.6/BUILD/libauxin-player-1.6/src/
make -C build $NAME.clean
make -C build $NAME

fi

cd /home/mmes/build
sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt;"
sshpass -p root scp $FILE root@192.168.0.2:/dev/shm
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio /dev/shm/$NAME*.rpm|cpio -ivd;sync"


