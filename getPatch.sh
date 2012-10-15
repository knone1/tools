

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
	HASDATA=`cat temp.txt`
	if [ -z "$HASDATA" ]; then
		git log >temp.txt
	fi
	ISPRESENT=`cat temp.txt|grep $CHANGEID`	
	rm temp.txt
	if [ -z "$ISPRESENT" ]; then
		ISPRESENT=0
	else
		ISPRESENT=1
	fi
	cd $REPO_ROOT
}

is_dir_ok()
{
	cd $REPO_ROOT
	if [ -e "$PROJECT_DIR" ]; then
		ISDIROK=1
	else
		ISDIROK=0
	fi	
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

get_patch_data()
{
	clean_vars;
	PATCH_NUMBER=$1
	LAST_TWO=`echo $PATCH_NUMBER| awk '{ print substr( $PATCH_NUMBER, length($PATCH_NUMBER) - 1, length($PATCH_NUMBER) ) }'`

	#go to some git dir, to be able to talk to gerrit
	cd build
	if [ $ISBRCM -eq 1 ]; then
		ssh -p 29418 mcg-pri-gcr.jf.intel.com gerrit query --current-patch-set $PATCH_NUMBER > t.txt
	else
		ssh -p 29418 android.intel.com gerrit query --current-patch-set $PATCH_NUMBER > t.txt
	fi
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
	cd $REPO_ROOT	
	is_dir_ok;
	if [ $ISDIROK -eq 1 ]; then	
		is_patch_present;
	fi

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
#	echo "RAWDATA = $RAWDATA"
	echo "*********************************"


}

apply_patch()
{
	cd $PROJECT_DIR
	if [ $ISPRESENT -eq 0 ]; then	
		if [ $ISBRCM -eq 1 ]; then
			git fetch git://mcg-pri-gcr.jf.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git cherry-pick FETCH_HEAD
		else
			git fetch git://android.intel.com/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git cherry-pick FETCH_HEAD
		fi
	else
		echo "PATCH $PATCH_NUMBER is present, not apply"
	fi
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
		CLEAN=`echo $ISDIRTY|awk '
		BEGIN{
			FS="/"
		}
		{
			i = NF -1
			print $i
		}'`
	else
		CLEAN=$1
	fi
}

set_brcm()
{
	ISBRCM=1
}
run_action()
{
	sanity;
	clean_argument $1;
	get_patch_data $CLEAN;
	if [ $MODE -eq 0 ]; then
		patchReport;
	fi
	if [ $MODE -eq 1 ]; then
		patchReportShort;
	fi
	if [ $MODE -eq 2 ]; then
		apply_patch
	fi
	if [ $MODE -eq 3 ]; then
		revert_patch
	fi

}
usage()
{
echo "Usage is:
getPatch <option> <patch list> <option > <patch list > ...

-patch list is a gerrit link or gerrit patch number.
-opiton will apply to all patches that follow it. 
-patch can be in format of:
	http://android.intel.com:8080/#/c/67880/ 
	67880
	https://mcg-pri-gcr.jf.intel.com:8080/#/c/103/
- options are:
	pr - print patch info, is it applied?
	prs - print patch info short version
	apply - try to apply patch
	revert - revert patch
	brcm - patches are from brcm gerrit.

-example:
	getPatch.sh 67871 https://mcg-pri-gcr.jf.intel.com:8080/#/c/103/ brcm 200
	getPatch.sh 67871 67873 67874 70852
	getPatch.sh http://android.intel.com:8080/#/c/70006/

"



}

main ()
{
	
	while [ ! -z "$1" ]; do
	        case $1 in
	       	pr)     MODE=0;;
		prs)	MODE=1;;
		apply)	MODE=2;;
		revert) MODE=3;;
		brcm) set_brcm;;
		help) usage;exit;;
		-help)	usage;exit;;
		--help) usage;exit;;
		*) run_action $1;;
        	esac
        	shift
	done
}

main "$@";

