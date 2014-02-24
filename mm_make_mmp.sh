
cd /home/mmes/build

rm /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-mmp-*


cp -rf /home/mmes/GITS/multimedia/dist/vmost-mmp/src/src/mmp/* /home/mmes/build/build/vmost-mmp-0.5/src/mmp/
make -C build vmost-mmp.clean
make -C build vmost-mmp



sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"
sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-mmp-* root@192.168.0.2:/
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-mmp-*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-mmp-debug*.rpm|cpio -ivd;sync"


