test(){
ROOT=$PWD

repo forall -c "pwd;cat ./.git/config|grep projectname" > .getPatchIndex.txt


while read line
do
	ISPROJ=`echo $line|grep projectname`
	echo "ISPROj.. $ISPROJ"
	if [ -z "$ISPROJ" ];then
		echo "cd $line"
		cd $line
	else
		 PROJ=`echo $line|awk '{print $3}'`
		 echo "project is ... $PROJ"
		 COMMIT=`cat $ROOT/.repo/manifest.xml |grep $PROJ|awk 'BEGIN{FS="revision"}{print $2}'|cut -c 3-8`
		 echo "Commit is ... $COMMIT"
		 git reset --hard $COMMIT
	fi
	
done <./.getPatchIndex.txt

}

#repo forall -c "git l -1">./t.txt
cat ./t.txt|awk '{print $1}' >./t2.txt 
while read line
do

	echo $line
	OK=`grep -nri $line ./.repo/manifest.xml`
	if [ -z "$OK" ]; then
		echo "ERROR";
	fi

done <./t2.txt

