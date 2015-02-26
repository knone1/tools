FILE=$1

#DIR1=/home/axelh/GITS/linux-max1-new
#DIR2=/home/axelh/GITS/linux-max1


DIR1=/home/axelh/GITS/linux-ll
DIR2=/home/axelh/GITS/linux-ti

echo "aaa $1 $DIR1 $DIR2"

bcompare $DIR1/$FILE $DIR2/$FILE &



