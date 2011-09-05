
COMMIT=$1

git show --pretty=email  $COMMIT >./thePatch.patch
git revert $COMMIT --no-edit
git am ./thePatch.patch


