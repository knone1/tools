
case $1 in
main) 
git branch -D main
git checkout --track -b main remotes/umg/platform/android/main ;;
mr1) git checkout --track -b mr1 remotes/umg/integ/jellybean/4.2_r1/main;;
*) echo "no branch $1"
esac



#git checkout --track -b merr_a0_poweron remotes/umg/integ/android/merr_a0_poweron


