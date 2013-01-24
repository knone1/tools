
add_tag() {
FILE=$1
TAG=$2
SUBJECT=`cat $FILE|grep "Subject:"|awk 'BEGIN{FS="]"}{print $2}'`
SUBJECT=`echo "Subject: $TAG$SUBJECT"`
LINE=`cat $FILE|grep -n "Subject:"|awk 'BEGIN{FS=":"}{print $1}'`
awk -v "r=${SUBJECT}" 'NR==4 {$0=r} { print }' $FILE > t.txt
mv ./t.txt $FILE

echo $FILE
}

rm -f ./P
mkdir P

git checkout main
git format-patch -$1 -o ./P
cd ./P

ls -1 > ./f.txt

while read line
do 
	add_tag $line "[PORT FROM MAIN]"
done < ./f.txt
rm ./f.txt

cd ..
git checkout mr1
git am -k ./P/*
rm -rf ./P


