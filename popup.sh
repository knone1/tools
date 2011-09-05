
DIR=./popup
COMMIT=$1

mkdir $DIR
rm -rf $DIR/*

git format-patch $COMMIT..HEAD -o $DIR
git reset --hard $COMMIT
