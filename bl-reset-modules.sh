rm -rf tmp
mkdir tmp
make -j8 ARCH=arm CROSS_COMPILE=/home/axelh/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf- LOADADDR=0x80008000 modules_install INSTALL_MOD_PATH=`pwd`/tmp

cd ./tmp/lib/modules
tar cvf modules.tar *
bl-push.sh modules.tar

sshpass -p ubuntu ssh ubuntu@192.168.10.4 "sudo rm -rf /lib/modules/*"
sshpass -p ubuntu ssh ubuntu@192.168.10.4 "cd /lib/modules; sudo tar xvf ~/modules.tar; rm ~/modules.tar "
sshpass -p ubuntu ssh ubuntu@192.168.10.4 "sync	"

