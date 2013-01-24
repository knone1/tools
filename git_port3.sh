
help(){
echo "
Assumming your patch is on gerrit..
usage: git_port.shi <GERRIT_USER> <GERRIT_PATCH#> <TO>

supported TO branches: 

main:	 platform/android/main
mr1:	 integ/jellybean/4.2_r1/main
r3:	 platform/android/r3-stable
r4:	 platform/android/r4.1-stable
enzo:	 platform/android/r4-enzo

"
}

get_data(){
	I_PATCH_NUMBER=$1

	echo "Getting patch $I_PATCH_NUMBER info..."
	ssh -p 29418 android.intel.com gerrit query --current-patch-set $I_PATCH_NUMBER > t.txt
        I_PATCHSET=`cat t.txt |grep number|tail -1|awk '{print $2}'`
        I_PROJECT=`cat t.txt|grep project |tail -1|awk '{print $2}'`
 	I_BRANCH=`cat t.txt|grep branch: |tail -1|awk '{print $2}'`
        I_CHANGEID=`cat t.txt|grep change|grep -v :|awk '{print $2}'`
        I_SUBJECT=`cat t.txt|grep subject|awk 'BEGIN{FS="subject:"}{print $1 $2}'`
        I_PATCH_NUMBER=`cat t.txt|grep number:|head -1|awk '{print $2}'`
	I_LAST_TWO=`echo $I_PATCH_NUMBER| awk '{ print substr( $I_PATCH_NUMBER, length($I_PATCH_NUMBER) - 1, length($I_PATCH_NUMBER) ) }'`
        #rm t.txt
	
	echo "Getting patch $I_PATCH_NUMBER..."
	git fetch  $GERRIT:29418/$I_PROJECT refs/changes/$I_LAST_TWO/$I_PATCH_NUMBER/$I_PATCHSET && git format-patch -1 --stdout FETCH_HEAD 2>&1>/dev/null > ./$I_PATCH_NUMBER.patch
}

git_checkout()
{
	BRANCH_NAME=`echo "p-$1"`
	REMOTE=`echo "remotes/umg/$2"`
	echo "Check if remotes/umg/$2 exists..."
	BRANCH_OK=`git branch -a|grep remotes/umg/$2`
	if [ -z $BRANCH_OK ]; then
		echo "Error, remotes/umg/$2 does not seem to exist for this project."
		exit
	fi

	echo "Checking out... name=$BRANCH_NAME remote=$REMOTE"
	git branch -D $BRANCH_NAME; 
	git checkout --track -b $BRANCH_NAME $REMOTE	
} 


main()
{

ARG_USER=$1
ARG_NUM=$2
ARG_TO=$3

GERRIT="ssh://$ARG_USER@android.intel.com"

B_MAIN="platform/android/main"
B_MR1="integ/jellybean/4.2_r1/main"
B_R3="platform/android/r3-stable"
B_R4="platform/android/r4.1-stable"
B_ENZO="platform/android/r4-enzo"

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

	echo "Switching to latest on destination branch $ARG_TO..."
	git_checkout $ARG_TO $TO_B;
	

	#make sure we are on the latest.
	echo "Pulling to latest code..."
	git pull

	#get the patch
	echo "Getting patch $ARG_COMMIT..."
	rm -rf $ARG_NUM.patch
	get_data $ARG_NUM
	FILE=`echo $ARG_NUM.patch`

	if [ ! -e $FILE ]; then	
		echo "Error getting patch $ARG_NUM. exit."
		exit
	fi

	#Adding tag to subject
	echo "Adding tag $TAG to subject..."
	case $I_BRANCH in
		platform/android/main)		TAG="[PORT-FROM-MAIN]";;
		integ/jellybean/4.2_r1/main)	TAG="[PORT-FROM-MR1]";;
		platform/android/r3-stable)	TAG="[PORT-FROM-R3]";;
		platform/android/r4.1-stable)	TAG="[PORT-FROM-R4]";;
		platform/android/r4-enzo)	TAG="[PORT-FROM-ENZO]";;
		*)	echo "$I_BRANCH tag not supported. exit"
			exit;;
	esac

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
	git am -k $FILE

	#check if applied ok
	echo "Checking if applied OK..."
	git show>latest.txt
	CHANGEID2=`cat ./latest.txt|grep Change-Id:|awk '{print $2}'`
	rm ./latest.txt

	if [ "$I_CHANGEID" != "$CHANGEID2" ]; then
		echo "patch did not apply on $ARG_TO exit."
		git am --abort	
		exit
	else
		echo "Patch applied correctly on $ARG_TO!"
	fi
	
	#pushing to gerrit the new patch
	echo "Pushing to gerrit the new patch..."
#	cat ./.git/config > t.txt
#	PROJECT=`cat t.txt|grep projectname|awk '{print $3}'`
#	git push ssh://ahaslamX@android.intel.com:29418/$PROJECT.git HEAD:refs/for/$TO_B
#	rm -rf ./t.txt
}


main $1 $2 $3



