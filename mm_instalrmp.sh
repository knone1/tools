
PKG=$1

sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"
sshpass -p root scp $PKG root@192.168.0.2:/
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./*.rpm|cpio -ivd;sync"






