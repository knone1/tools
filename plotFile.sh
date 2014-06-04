



FILENAME=$1

export NAME=$FILENAME".png"
export FILENAME2=$1

gnuplot  << \__EOF
    filename=system("echo $FILENAME2")
    name2=system("echo $NAME")
    set term png
    set output name2
    plot filename with steps
__EOF



eog  $FILENAME.png



