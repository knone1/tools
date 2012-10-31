#PATCH DATA
PATCH_NUMBER=0
LAST_TWO=0
PATCH_INFO=0
LATEST_PATCHSET=0
PROJECT=0
PROJEC_DIR=0
ISPRESENT=0
ISDIROK=0
SUBJECT=0
RAWDATA=0

#PROGRAM FLOW
MODE=1  
RET=0
REPO_ROOT=0
ISBRCM=0
DEBUG=0

#CONSTANTS
START_PATH=$PWD

debug_print() 
{
	if [ $DEBUG -eq 1 ]; then
		echo "DEBUG: " $1
	fi
}

sanity()
{
	if [ ! -e ".repo" ]; then
		echo "plaese run from repo root!"
		exit 1;
	fi
	REPO_ROOT=$PWD
}

is_patch_present()
{
	cd $PROJECT_DIR
	git log HEAD~100..HEAD 2>/dev/null>temp.txt

	#git log may be too small

	HASDATA=`cat temp.txt`
	debug_print "HASDATA" $HASDATA
	if [ -z "$HASDATA" ]; then
		git log >temp.txt
	fi

	#find the change if on the git log.
	ISPRESENT=`cat temp.txt|grep $CHANGEID`	

	rm temp.txt

	if [ -z "$ISPRESENT" ]; then
		ISPRESENT=0
	else
		ISPRESENT=1
	fi
	cd $REPO_ROOT

	debug_print "is_patch_present ISPRESENT" $ISPRESENT
}

is_dir_ok()
{
	cd $REPO_ROOT
	if [ -e "$PROJECT_DIR" ]; then
		ISDIROK=1
	else
		ISDIROK=0
	fi	
	debug_print "is_dir_ok ISDIROK" $ISDIROK
}

clean_vars()
{
	PATCH_NUMBER=0
	LAST_TWO=0
	PATCH_INFO=0
	LATEST_PATCHSET=0
	PROJECT=0
	PROJEC_DIR=0
	ISPRESENT=0
	ISDIROK=0
	SUBJECT=0
	RAWDATA=0

}

fix_dir_quirk()
{
	debug_print "fix_dir_quirk enter $PROJECT_DIR"
	#some projects patch are not the same as project git.
	if [ "$PROJECT_DIR" = "platform/system/bluetooth/" ]; then
		PROJECT_DIR="system/bluetooth/"
	fi
	if [ "$PROJECT_DIR" = "platform/frameworks/base/" ]; then
		PROJECT_DIR="frameworks/base/"
	fi
	debug_print "fix_dir_quirk exit $PROJECT_DIR"

}

get_patch_data()
{
	debug_print "get_patch_data enter"
	clean_vars;
	PATCH_NUMBER=$1

	#get the last two digits
	LAST_TWO=`echo $PATCH_NUMBER| awk '{ print substr( $PATCH_NUMBER, length($PATCH_NUMBER) - 1, length($PATCH_NUMBER) ) }'`

	#go to some git dir, to be able to talk to gerrit
	cd build
	if [ $ISBRCM -eq 1 ]; then
		ssh -p 29418 mcg-pri-gcr.jf.intel.com gerrit query --current-patch-set $PATCH_NUMBER > t.txt
	else
		ssh -p 29418 android.intel.com gerrit query --current-patch-set $PATCH_NUMBER > t.txt
	fi
	
	#parse the info
	PATCH_INFO=`cat t.txt`
	LATEST_PATCHSET=`cat t.txt |grep number|tail -1|awk '{print $2}'`
	PROJECT=`cat t.txt|grep project |tail -1|awk '{print $2}'`
	RAWDATA=`cat t.txt`
	PROJECT_DIR=`echo $PROJECT|awk 'BEGIN{FS="/"}{
			for (i=3;i<=NF;i++){
				printf  $i "/"
			}
		}'`
	CHANGEID=`cat t.txt|grep change|grep -v :|awk '{print $2}'`
	SUBJECT=`cat t.txt|grep subject|awk 'BEGIN{FS="subject:"}{print $1 $2}'`

	fix_dir_quirk;

	cd $REPO_ROOT	

	is_dir_ok;
	if [ $ISDIROK -eq 1 ]; then	
		is_patch_present;
	fi

        debug_print "------------------------------"
        debug_print "PATCH = $PATCH_NUMBER"
        debug_print "PROJECT = $PROJECT"
        debug_print "PATCHSET = $LATEST_PATCHSET"
        debug_print "PROJECT DIR = $PROJECT_DIR"
        debug_print "ISDIROK =  $ISDIROK"
        debug_print "CHANGE ID = $CHANGEID"
        debug_print "ISPRESENT = $ISPRESENT"
        debug_print "------------------------------"

	debug_print "get_patch_data exit"

}

patchReport()
{
	echo "*********************************"
	echo "PATCH = $PATCH_NUMBER"
	echo "PROJECT = $PROJECT"
	echo "PATCHSET = $LATEST_PATCHSET"
	echo "PROJECT DIR = $PROJECT_DIR"
	echo "ISDIROK =  $ISDIROK"
	echo "CHANGE ID = $CHANGEID"
	echo "ISPRESENT = $ISPRESENT"
	debug_print "RAWDATA = $RAWDATA"
	echo "*********************************"
}

apply_patch()
{
	cd $PROJECT_DIR

	debug_print "apply_patch ISPRESENT $ISPRESENT ISDIROK $ISDIROK"

	if [ $ISPRESENT -eq 0 ]; then	
		if [ $ISBRCM -eq 1 ]; then
			git fetch ssh://ahaslamx@mcg-pri-gcr.jf.intel.com:29418/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git cherry-pick FETCH_HEAD
		else
			git fetch git://android.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git cherry-pick FETCH_HEAD
		fi
	else
		echo "PATCH $PATCH_NUMBER is present, not apply"
	fi
	cd $REPO_ROOT
}

revert_patch()
{
	echo "REVERT NOT IMPLEMENTED YET."
}

patchReportShort()
{
	if [ $ISPRESENT -eq 1 ]; then
		echo "$PATCH_NUMBER - IS PRESENT - $SUBJECT"
	else
		echo "$PATCH_NUMBER - IS NOT PRESENT - $SUBJECT"
	fi
}

clean_argument()
{
	ISDIRTY=`echo $1|egrep "android.intel.com|mcg-pri-gcr.jf.intel.com"`
	if [ ! -z $ISDIRTY ]; then
		#extract BZID.
		CLEAN=`echo $ISDIRTY|awk '
		BEGIN{FS="/"}
		{
			i = NF -1
			print $i
		}'`
	else
		CLEAN=$1
	fi

	debug_print "clean_argument $1 cleaned is:$CLEAN"
}

set_brcm()
{
	ISBRCM=1
}

get_patch()
{
	debug_print "cd $START_PATH/$PROJECT_DIR"
	cd $REPO_ROOT/$PROJECT_DIR

	echo "Getting Patch ... $PATCH_NUMBER"
	if [ $ISBRCM -eq 1 ]; then
		debug_print "get_patch git fetch ssh://ahaslamx@mcg-pri-gcr.jf.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD > $START_PATH/$PATCH_NUMBER.patch"
		git fetch ssh://ahaslamx@mcg-pri-gcr.jf.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD > $START_PATH/$PATCH_NUMBER.patch
	else
		debug_print "git fetch git://android.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD > $START_PATH/$PATCH_NUMBER.patch"
		git fetch git://android.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD > $START_PATH/$PATCH_NUMBER.patch
	fi
	cd $REPO_ROOT
	
}

run_action()
{
	sanity;
	clean_argument $1;
	get_patch_data $CLEAN;

	debug_print "run_action MODE $MODE $1"

	case $MODE in
	0)patchReport;;
	1)patchReportShort;;
	2)apply_patch;;
	3)revert_patch;;
	4)get_patch;;
	*)echo "UNKNOWN MODE $MODE" ;;
	esac
}

usage()
{
echo "Usage is:
getPatch <OPTION> <PATCH_LIST> <OPTION> <PATCH_LIST> ...

getPatch tries to administer gerrit patches on your
local repo. it should always run from the root dir 
of the repo. 

-<PATCH_LIST> is a gerrit link or gerrit patch number.
-<OPTION> will apply to all patches that follow it. 

-PATCH_LIST should contian gerrit number and can be in format of:
	http://android.intel.com:8080/#/c/67880/ 
	67880
	https://mcg-pri-gcr.jf.intel.com:8080/#/c/103/

-options are:
	-prv - print verbose patch info
	-prs - print short patch info
	-apply - try to apply patch
	-revert - try to revert patch
	-brcm - patches are from brcm gerrit.
	-gp - Get Patch - get .patch file

-example:
	getPatch.sh 67871 https://mcg-pri-gcr.jf.intel.com:8080/#/c/103/ brcm 200
	getPatch.sh 67871 67873 67874 70852
	getPatch.sh http://android.intel.com:8080/#/c/70006/


"



}

main ()
{
	while [ ! -z "$1" ]; do
		debug_print "main $1"
	        case $1 in
	       	-prv)     MODE=0;;
		-prs)	MODE=1;;
		-apply)	MODE=2;;
		-revert) MODE=3;;
		-brcm) set_brcm;;
		-gp) MODE=4;;
		-DEBUG) DEBUG=1;;
		-help) usage;exit;;
		-help)	usage;exit;;
		--help) usage;exit;;
		*) run_action $1;;
        	esac
        	shift
	done
}

main "$@";

