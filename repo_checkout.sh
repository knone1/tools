
case $1 in
main) repo forall -c "git checkout --track -b main remotes/umg/platform/android/main" ;;
*) echo "no branch $1"
esac
