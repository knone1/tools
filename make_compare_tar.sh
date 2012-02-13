cd ~/r3/$1

echo "taring.." ~/r3/$1
tar -cjf ~/BOX/OUT/r3.tar.bz *

echo "taring.." ~/r2/$1
cd ~/r2/$1

tar -cjf ~/BOX/OUT/r2.tar.bz *

echo "DONE"
