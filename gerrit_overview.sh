REPO_ROOT=$PWD
SERVER="android.intel.com"


get_gerrit_id()
{
	LINE=$1
	COMMIT_ID=`echo "$LINE" |awk '{print $2}'`
	CHANGE_ID=`git show $COMMIT_ID|grep Change-Id|awk '{print $2}'`
	ssh -p 29418 $SERVER gerrit query --current-patch-set $CHANGE_ID > t.txt
	#PATCH_NUMBER=`cat t.txt|grep number:|head -1|awk '{print $2}'`
	#echo "Change id is $CHANGE_ID patch number $PATCH_NUMBER"

}

set_project()
{
	LINE=$1
	PROJECT_DIR=`echo "$LINE" |awk '{print $2}'`
	cd $REPO_ROOT/$PROJECT_DIR
	echo "Project dir set to $REPO_ROOT/$PROJECT_DIR"
}



while read line
do
	IS_BRANCH=0
	IS_PATCH=0
	IS_PROJECT=0

	FIRST_FIELD=`echo "$line" |awk '{print $1}'`
	if [ "$FIRST_FIELD" == "*" ]; then
		IS_BRANCH=1
	fi
	if [ "$FIRST_FIELD" == "-" ]; then
		IS_PATCH=2
		get_gerrit_id "$line"
	fi
	if [ "$FIRST_FIELD" == "project" ]; then
		IS_PROJECT=3
		set_project "$line"
	fi
#	echo "$FIRST_FIELD $IS_BRANCH $IS_PATCH $IS_PROJECT"

done < ./overview.txt



