cat ./.git/config > t.txt
PROJECT=`cat t.txt|grep projectname|awk '{print $3}'`

git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for/platform/android/main
 
rm t.txt
