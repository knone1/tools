

rm -rf *
sshpass -p root scp root@192.168.0.2:/dev/shm/axe* .


ls -1 *.txt > files.txt

i=0

while read line
do

FILENAME=$line

echo $FILENAME
cat ./$FILENAME |grep -v - > t.txt
NAME=`echo "./$i.png"`
i=$(($i + 1))


export NAME=$FILENAME".png"
export FILENAME2="./t.txt"

echo $NAME
gnuplot  << \__EOF
    filename=system("echo $FILENAME2")
    name2=system("echo $NAME")
    set term png
    set output name2
    plot filename with steps
__EOF



done < files.txt
rm files.txt
#eog test1.jpg




