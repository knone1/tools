phy 0 off
sleep 5
echo -e "cat /proc/wakelocks | awk '{print \$1 \042 \042 \$5}' |grep -v \042 0\042 |grep -v active" > ~/kw.sh
chmod 777 ~/kw.sh
adb push ~/kw.sh /data/kw.sh
adb shell "/data/kw.sh > /data/kw.txt"
adb pull /data/kw.txt ~/
echo "ACTIVE KERNEL WAKELOCKS:"
cat ~/kw.txt
phy 0 on
