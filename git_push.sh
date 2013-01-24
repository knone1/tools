cat ./.git/config > t.txt
PROJECT=`cat t.txt|grep projectname|awk '{print $3}'`
BRANCH=`git branch -vvv |grep \* | awk '{print $4}'|awk 'BEGIN{FS=":"}{print $1}'|awk 'BEGIN{FS="["}{print $2}'|awk 'BEGIN{FS="umg"}{print $2}'`

echo  "***********" 
echo "$BRANCH $PROJECT" 


git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for$BRANCH

#git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for/platform/android/r4-enzo
#git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for/platform/android/r4.1-stable

 #rm t.txt
