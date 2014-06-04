
echo "pushing $1"

if [ -z "$2" ]; then 
DST=/dev/shm
else
DST=$2
fi
sshpass -p root scp $1 root@192.168.0.2:$DST


