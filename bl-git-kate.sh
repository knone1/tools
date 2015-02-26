kate `git status |grep modified:|awk '{print $2}'; git status|grep -v modified|egrep "\.c|\.h"` &

