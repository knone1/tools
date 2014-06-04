
ls -1 axdata*.txt > files.txt


while read line
do
FILENAME=$line
export NAME=$FILENAME".png"
export FILENAME2=$FILENAME

gnuplot  << \__EOF
    filename=system("echo $FILENAME2")
    name2=system("echo $NAME")
    set term png
    set output name2
    plot filename with steps
__EOF




done < files.txt

#eog  $FILENAME.png
#rm /home/mmes/VMSHARE/TTTTTTTT/*
mv *.png /home/mmes/VMSHARE/plot/
cp *.txt /home/mmes/VMSHARE/plot/
