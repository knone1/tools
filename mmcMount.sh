echo "**********************"
echo " Mounting"
echo "**********************"
mkdir /media/boot
mkdir /media/fileSystem

mount -t vfat /dev/sdb1 /media/boot
mount -t ext3 /dev/sdb2 /media/fileSystem