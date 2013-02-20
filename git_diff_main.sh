GIT_DIRECTORY=`git rev-parse --git-dir`
PROJECT_NAME=`cat $GIT_DIRECTORY/config |grep projectname|awk '{print $3}'`
MAIN_COMMIT=`git branch -a -vv |grep "umg/platform/android/main "|awk '{print $2}'`
NUMBER_OF_PATCHES=`git log --oneline $MAIN_COMMIT..HEAD|wc -l`
DIFF=`git diff`
if [ $NUMBER_OF_PATCHES -ne "0" ]; then 
	echo "*******************************************"
	echo $PROJECT_NAME
	git log --oneline HEAD~$NUMBER_OF_PATCHES..HEAD
fi

if [ ! -z "$DIFF" ]; then 
	echo "*******************************************"
	echo $PROJECT_NAME "HAS UNCOMMITED CHANGES"
fi


