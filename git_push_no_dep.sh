rm -rf .pusher
mkdir .pusher

cat ./.git/config > t.txt
PROJECT=`cat t.txt|grep projectname|awk '{print $3}'`
BRANCH=`git branch -vvv |grep \* | awk '{print $4}'|awk 'BEGIN{FS=":"}{print $1}'|awk 'BEGIN{FS="["}{print $2}'|awk 'BEGIN{FS="umg"}{print $2}'`
BRANCH_NAME=`git branch -vvv |grep \* | awk '{print $2}'`


git format-patch -1 -o ./pusher
git reset --hard HEAD~1
git branch -D T1
git checkout -b T1
git am ./pusher/0001*

git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for$BRANCH
git checkout $BRANCH_NAME
git am ./pusher/0001*
rm -rf ./pusher








