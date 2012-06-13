i=0
while true; do
echo $i
adb shell input keyevent $i
i=`expr $i + 1`
sleep 1
done;
