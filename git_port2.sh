



help(){
echo "usage: git_port.sh <FROM> <TO> 
Branch could be:
 main
 mr1
 enzo
 r3
 r4
"
}

git_checkout()
{
	BRANCH_NAME=`echo "p-$1"`
	REMOTE=`echo "remotes/umg/$2"`
	echo "Checking out... name=$BRANCH_NAME remote=$REMOTE"
	git branch -D $BRANCH_NAME; git checkout --track -b $BRANCH_NAME $REMOTE
	
} 


main()
{
ARG_FROM=$1
ARG_TO=$2
ARG_COMMIT=$3

B_MAIN="platform/android/main"
B_MR1="integ/jellybean/4.2_r1/main"
B_R3="platform/android/r3-stable"
B_R4="platform/android/r4-stable"
B_ENZO="platform/android/r4-enzo"

	case $ARG_FROM in
		main)	TAG="[PORT-FROM-MAIN]"
			FROM_B=$B_MAIN
			;;
		mr1)	TAG="[PORT-FROM-MR1]"
			FROM_B=$B_MR1
			;;
		r3)	TAG="[PORT-FROM-R3]"
			FROM_B=$B_R3
			;;
		r4)	TAG="[PORT-FROM-R4]"
			FROM_B=$B_R4
			;;
		enzo)	TAG="[PORT-FROM-ENZO]"
			FROM_B=$B_ENZO
			;;
		*)	echo "$ARG_FROM not found. exit"
			exit
			;;
	esac
	
	case $ARG_TO in
		main)	TO_B=$B_MAIN
			;;
		mr1)	TO_B=$B_MR1
			;;
		r3)	TO_B=$B_R3
			;;
		r4)	TO_B=$B_R4
			;;
		enzo)	TO_B=$B_ENZO
			;;
		*)	echo "$ARG_TO not found. exit"
			exit
			;;
	esac

	echo "Switching to latest on $ARG_TO..."
	git_checkout $ARG_TO $TO_B;

	#make sure we are on the latest.
	echo "Pulling to latest code..."
	git pull

	#get the patch
	echo "Getting patch $ARG_COMMIT..."
	rm -rf ./.port
	git format-patch $ARG_COMMIT -1  -o ./.port
	FILE=`ls -1 ./.port`
	FILE=`echo "./.port/$FILE"`
	CHANGEID=`cat $FILE|grep Change-Id:|awk '{print $2}'`

	#Adding tag to subject
	echo "Adding tag $TAG to subject..."
	SUBJECT=`cat $FILE|grep "Subject:"|awk 'BEGIN{FS="]"}{print $2}'|cut -c 2-999`
	SUBJECT=`echo "Subject: $TAG$SUBJECT"`
	LINE=`cat $FILE|grep -n "Subject:"|awk 'BEGIN{FS=":"}{print $1}'`
	awk -v "r=${SUBJECT}" 'NR==4 {$0=r} { print }' $FILE > t.txt
	mv ./t.txt $FILE
	rm t.txt
	
	NEW_SUBJECT=`cat $FILE|grep "Subject:"`
	echo "Subject line changed to: $NEW_SUBJECT"
	
	#apply the patch
	echo "Trying to apply $ARG_COMMIT on $ARG_TO..."
	git am -k ./.port/*.patch

	#check if applied ok
	echo "Checking if applied OK..."
	git show>latest.txt
	CHANGEID2=`cat ./latest.txt|grep Change-Id:|awk '{print $2}'`
	rm ./latest.txt

	if [ "$CHANGEID" != "$CHANGEID2" ]; then
		echo "patch did not apply on $ARG_TO exit."
		git am --abort	
		exit
	else
		echo "Patch applied correctly on $ARG_TO!"
	fi
	
	#pushing to gerrit the new patch
	echo "Pushing to gerrit the new patch..."
	#cat ./.git/config > t.txt
	#PROJECT=`cat t.txt|grep projectname|awk '{print $3}'`
	#git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for/$TO_B

}


main $1 $2 $3



