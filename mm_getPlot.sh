
rm -rf ./axPlot/
mkdir ./axPlot/
sshpass -p root ssh root@192.168.0.2 "rm /dev/shm/axdata*"
echo "sleep "
sleep 10;
echo "sleep done"
sshpass -p root scp root@192.168.0.2:/dev/shm/axdata*_1.txt ./axPlot/



echo "Done getting files.. generating plot"

cd ./axPlot/



ls -1 axdata*.txt > files.txt




while read line
do
FILENAME=$line
export NAME=$FILENAME".png"
export FILENAME2=$FILENAME
echo "plotting $FILENAME"
gnuplot  << \__EOF
    filename=system("echo $FILENAME2")
    name2=system("echo $NAME")
    set term png
    set output name2
    plot filename with steps
__EOF

done < files.txt

rm -rf ~/VMSHARE/plot
mkdir ~/VMSHARE/plot

cp *.png ~/VMSHARE/plot/
cp *.txt ~/VMSHARE/plot/
