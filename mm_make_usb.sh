
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-usb-1.6-1_WR3.0.2ax.armv6jel_vfp-22daffa.rpm
#Wrote: /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-usb-debuginfo-1.6-1_WR3.0.2ax.armv6jel_vfp-22daffa.rpm



cd ~/build
rm /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-usb-*


make -C build vmost-auxin-usb.clean
make -C build vmost-auxin-usb



sshpass -p root ssh root@192.168.0.2 "mount -o rw,remount  /opt; cd /;rm *.rpm"
sshpass -p root scp /home/mmes/build/export/RPMS/armv6jel_vfp/vmost-auxin-usb-* root@192.168.0.2:/

sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-auxin-usb-1*.rpm|cpio -ivd;sync"
sshpass -p root ssh root@192.168.0.2 "cd /; rpm2cpio ./vmost-auxin-usb-debuginfo-*.rpm|cpio -ivd;sync"



