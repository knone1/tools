apt-get install git-core
apt-get install curl
apt-get install corkscrew


cd ~/bin
curl http://android.git.kernel.org/repo > ~/bin/repo
chmod a+x ~/bin/repo


echo "[core]">~/.gitconfig
echo "       gitproxy = /home/axel/git-proxy.sh">>~/.gitconfig
echo "[user]">>~/.gitconfig
echo "     email = axelhaslam@ti.com">>~/.gitconfig
echo "     name = Axel Haslam">>~/.gitconfig
echo "[color]">>~/.gitconfig
echo "     diff = auto">>~/.gitconfig
echo "     status = auto">>~/.gitconfig
echo "     branch = auto">>~/.gitconfig

echo "#!/bin/sh">~/git-proxy.sh
echo "exec /usr/bin/corkscrew wwwgate.ti.com 80 $*">>~/git-proxy.sh

