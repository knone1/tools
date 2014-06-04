
FILE=$1
START=$2
END=$3

cat $FILE |tail -n +$START|head -n $(($END - $START))


