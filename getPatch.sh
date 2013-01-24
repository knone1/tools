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
PATCHSET=0

#PROGRAM FLOW
MODE=1  
RET=0
REPO_ROOT=0
ISBRCM=0
DEBUG=0

#CONSTANTS
START_PATH=$PWD

GERRIT="ssh://ahaslamx@android.intel.com"
SERVER="android.intel.com"
USER=ahaslamx

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

set_brcm()
{
	ISBRCM=1
	GERRIT=ssh://$USER@mcg-pri-gcr.jf.intel.com
	SERVER=mcg-pri-gcr.jf.intel.com
}

set_intel()
{
	ISBRCM=0
	GERRIT=ssh://$USER@android.intel.com
	SERVER=android.intel.com
}

is_patch_present()
{
	cd $PROJECT_DIR

	#look for change id in last 100 commits..
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
	PATCHSET=0
}

get_project_dir() {
	cd $REPO_ROOT
	debug_print $PROJECT
	if [ ! -e .getPatchIndex.txt ]; then
		echo "generating project index file"
		repo forall -c "cat ./.git/config|grep projectname;pwd" > .getPatchIndex.txt
	fi
	PROJECT_DIR=`cat .getPatchIndex.txt |grep -A 1 $PROJECT|tail -1`
	debug_print $PROJECT_DIR
}

get_patch_data()
{
	debug_print " enter get_patch_data"
	clean_vars;
	PATCH_NUMBER=$1
	PATCH_INPUT=$1
	#get the last two digits
	LAST_TWO=`echo $PATCH_NUMBER| awk '{ print substr( $PATCH_NUMBER, length($PATCH_NUMBER) - 1, length($PATCH_NUMBER) ) }'`

	cd $REPO_ROOT

	ssh -p 29418 $SERVER gerrit query --current-patch-set $PATCH_NUMBER > t.txt

	#parse the info
	PATCH_INFO=`cat t.txt`
	LATEST_PATCHSET=`cat t.txt |grep number|tail -1|awk '{print $2}'`
	PROJECT=`cat t.txt|grep project |tail -1|awk '{print $2}'`
	RAWDATA=`cat t.txt`
#	PATCHSET=`ssh -p 29418 $SERVER gerrit query --current-patch-set 203 |grep -A 1 currentPatchSet|grep number|awk '{print $2}'`
	CHANGEID=`cat t.txt|grep change|grep -v :|awk '{print $2}'`
	SUBJECT=`cat t.txt|grep subject|awk 'BEGIN{FS="subject:"}{print $1 $2}'`
	PATCH_NUMBER=`cat t.txt|grep number:|head -1|awk '{print $2}'`
	rm t.txt

	#find the project
	get_project_dir;	

	#check if directory exists
	is_dir_ok;
	if [ $ISDIROK -eq 1 ]; then
		#check if the change id is in the history
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
	debug_print "exit get_patch_data"

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
	debug_print "enter apply_patch ISPRESENT = $ISPRESENT ISDIROK = $ISDIROK"

	cd $REPO_ROOT
	if [ $ISDIROK -eq 0 ]; then
		echo "Project dir $PROJECT_DIR does not exit for $PATCH_NUMBER, did not apply!"
		return 1
	fi
	cd $PROJECT_DIR

	if [ $ISPRESENT -eq 0 ]; then
		git fetch $GERRIT/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git cherry-pick FETCH_HEAD 2>/dev/null
		#check if apply worked.
		git show 2>/dev/null>temp.txt
		ISPRESENT2=`cat temp.txt|grep $CHANGEID`
		if [ -z "$ISPRESENT2" ]; then
			echo "ERROR APPLING PATCH!!! $PATCH_NUMBER "
			echo "Aborting.."
			git am --abort;
			exit 1;
		fi

	else
		echo "PATCH $PATCH_NUMBER is present, not apply"
	fi

	cd $REPO_ROOT
}

patchReportShort()
{
	if [ $ISPRESENT -eq 1 ]; then
		echo "$PATCH_NUMBER - IS PRESENT - $PROJECT_DIR - $SUBJECT"
	else
		echo "$PATCH_NUMBER - IS NOT PRESENT - $PROJECT_DIR - $SUBJECT"
	fi
}

clean_argument()
{
	debug_print "enter clean_argument $1"

	ISDIRTY=`echo $1|egrep "android.intel.com|mcg-pri-gcr.jf.intel.com"`
	if [ ! -z $ISDIRTY ]; then
		#extract GERRIT number.
		CLEAN=`echo $ISDIRTY|awk '
		BEGIN{FS="/"}
		{
			i = NF -1
			print $i
		}'`

		ISBRCM=`echo $1|egrep "mcg-pri-gcr.jf.intel.com"`
		if [ ! -z $ISBRCM ]; then
			set_brcm
		else
			set_intel
		fi

	else
		CLEAN=$1
	fi

	debug_print "exit clean_argument $1 cleaned is:$CLEAN"
}

get_patch()
{
	debug_print "enter get_patch"
	cd $REPO_ROOT
	if [ $ISDIROK -eq 0 ]; then
		echo "Project dir $PROJECT_DIR does not exit for $PATCH_NUMBER, did not apply!"
		return 1
	fi
	cd $PROJECT_DIR

	echo "Getting Patch ... $PATCH_NUMBER"
	debug_print "get_patch git fetch $GERRIT:29418/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD > $START_PATH/$PATCH_NUMBER.patch"

	git fetch  git://$SERVER/$PROJECT refs/changes/$LAST_TWO/$PATCH_NUMBER/$LATEST_PATCHSET && git format-patch -1 --stdout FETCH_HEAD 2>&1>/dev/null > $START_PATH/$PATCH_NUMBER.patch

	debug_print "exit get_patch"
}
show_patch()
{
	get_patch;
	cat $START_PATH/$PATCH_NUMBER.patch
	rm $START_PATH/$PATCH_NUMBER.patch
}

read_from_file()
{
	PATCHES=""
	while read line
	do
		PATCHES+=" "$line
	done < $1
	echo  $PATCHES

	#run list of patches..
	main $PATCHES
}

set_user()
{
	USER=$1
	echo "Set to USER=$USER"
}

add_review()
{
	echo "add_review for $PATCH_INPUT"

	ssh -p 29418 $SERVER gerrit set-reviewers \
	-a axelx.haslam@intel.com  \
	-a aymen.zayet@intel.com \
	-a christophe.fiat@intel.com \
	-a frodex.isaksen@intel.com \
	-a marcox.sinigaglia@intel.com \
	-a julie.regairaz@intel.com \
	-a quentinx.casasnovas@intel.com \
	-a jeremiex.garcia@intel.com \
	-a nicolas.champciaux@intel.com \
	-a pierrex.zurmely@intel.com \
	-a jean.trivelly@intel.com \
	$PATCH_INPUT
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
	-vv - print verbose patch info
	-check - check if patch is present
	-apply - try to apply patch
	-show - show the patch
	-review - add reviewers
	-reset - will revert all your local changes
	-status - will show the local patches.
	-brcm - patches are from brcm gerrit.
	-get - Get Patch - get .patch file

-example:
	1) Apply patches 67871 and 103

		getPatch.sh 67871 https://mcg-pri-gcr.jf.intel.com:8080/#/c/103/

	2)Apply patches 67871 67873 67874 70852 from android.intel.com
	and 200 201 from cg-pri-gcr.jf.intel.com:

		getPatch.sh -apply 67871 67873 67874 70852 -brcm 200 201

Options Details:

-vv -  verbose print
	getPatch.sh -vv 78411
	*********************************
	PATCH = 78411
	PROJECT = a/bsp/hardware/intel/linux-2.6
	PATCHSET = 5
	PROJECT DIR = /home/axelh/GITS/MAIN2/hardware/intel/linux-2.6
	ISDIROK =  1
	CHANGE ID = I3327cb268853307d85eb62e4e7caf58a06891a33
	ISPRESENT = 1
	*********************************

-check - check if patch is present
	getPatch.sh -check 78411
	78411 - IS PRESENT - /home/axelh/GITS/MAIN2/hardware/intel/linux-2.6 -    fix for mmc caps and rescan

-apply - apply patches from latst patchset (skip if present)
	getPatch.sh -apply 78411
	From ssh://android.intel.com/a/bsp/hardware/intel/linux-2.6
 	* branch            refs/changes/11/78411/5 -> FETCH_HEAD
	[main 9935ffe] fix for mmc caps and rescan
 	2 files changed, 6 insertions(+), 4 deletions(-)

-show - show the patch
	getPatch.sh -show 78411
	Getting Patch ... 78411
	From ssh://android.intel.com:29418/a/bsp/hardware/intel/linux-2.6
	 * branch            refs/changes/11/78411/5 -> FETCH_HEAD
	From f11c79158490b3e3b9f48fa38241ac3c79179c58 Mon Sep 17 00:00:00 2001
	From: Axel Haslam <axelx.haslam@intel.com>
	Date: Mon, 3 Dec 2012 15:15:27 +0100
	Subject: [PATCH] fix for mmc caps and rescan

	Change-Id: I3327cb268853307d85eb62e4e7caf58a06891a33
	Signed-off-by: Axel Haslam <axelx.haslam@intel.com>
	---
	 .../intel-mid/device_libs/platform_mmc_sdhci_pci.c |    4 ++--
	 drivers/mmc/host/sdhci-pci.c                       |    6 ++++--
	 2 files changed, 6 insertions(+), 4 deletions(-)

	[...

-review - add reviewers
	reviewers are harcoded on the script. WIP

-reset - will reset all local repo changes

-status - will show you your local patches
	

"
}


# this runs for each argument that is not 
# parced by main
run_action()
{
	cd $REPO_ROOT
	clean_argument $1;
	get_patch_data $CLEAN;

	debug_print "run_action MODE $MODE $1"

	case $MODE in
	0)patchReport;;
	1)patchReportShort;;
	2)apply_patch;;
	4)get_patch;;
	5)show_patch;;
	6)add_review;;
	*)echo "UNKNOWN MODE $MODE" ;;
	esac
}


#create CSV file of pro
get_changed_projects() 
{
	cd $REPO_ROOT
	repo forall -c "git status|egrep \"ahead|modified:|respectively.\";pwd;" |egrep -A 1 "ahead|modified|respectively." |grep home >  $REPO_ROOT/t.txt
	filelines=`cat $REPO_ROOT/t.txt`
	rm $REPO_ROOT/t.txt

	for line in $filelines 
	do
		cd $line
		STATUS=`git status |egrep ahead`
		NUMPATCHES=`echo $STATUS|awk '{print $9}'`
		if [ -z "$STATUS" ]; then
			STATUS=`git status |grep respectively.`
			NUMPATCHES=`echo $STATUS|awk '{print $4}'`
		fi

		UNCOMMITED=`git status |grep modified:|awk '{print $1}'`
		if [ ! -z "$UNCOMMITED" ]; then
			UNCOMMITED="YES"
		else
			 UNCOMMITED="NO"
		fi
		echo "$line,$NUMPATCHES,$UNCOMMITED"  >> $REPO_ROOT/t.txt
	done
}

repo_reset()
{
	cd $REPO_ROOT

	make_status
	filelines=`cat $REPO_ROOT/t.txt`
	for line in $filelines 
	do
		PROJECTDIR=`echo $line|awk 'BEGIN{FS=","}{print $1}'`
		NUMPATCHES=`echo $line|awk 'BEGIN{FS=","}{print $2}'`
		UNCOMMITED=`echo $line|awk 'BEGIN{FS=","}{print $3}'`
		echo "RESETING: $PROJECTDIR $NUMPATCHES local patch(es) +UNCOMMITED=$UNCOMMITED"
		cd $PROJECTDIR
		git reset --hard HEAD~$NUMPATCHES

	done


}
repo_status()
{
	cd $REPO_ROOT

	get_changed_projects
	filelines=`cat $REPO_ROOT/t.txt`
	for line in $filelines 
	do
		PROJECTDIR=`echo $line|awk 'BEGIN{FS=","}{print $1}'`
		NUMPATCHES=`echo $line|awk 'BEGIN{FS=","}{print $2}'`
		UNCOMMITED=`echo $line|awk 'BEGIN{FS=","}{print $3}'`
		echo "$PROJECTDIR $NUMPATCHES local patch(es) +UNCOMMITED=$UNCOMMITED"

		cd $PROJECTDIR
		for (( c=$(($NUMPATCHES - 1)); c>=0; c-- ))
		do
			CPROJ=`cat ./.git/config  |grep projectname|awk '{print $3}'`
			CHANGEID=`git show HEAD~$c|grep Change-Id|awk '{print $2}'`
			SUBJECT_LOCAL=`git show HEAD~$c|grep Date -A 2|tail -1`
			if [ ! -z $CHANGEID ]; then
				ssh -p 29418 android.intel.com gerrit query --current-patch-set  $CHANGEID |grep -A 5 $CPROJ>$REPO_ROOT/p.txt

				NUMBER=`cat $REPO_ROOT/p.txt|grep number -m 1|awk '{print $2}'`
				SUBJECT=`cat $REPO_ROOT/p.txt|grep subject|head -1|awk 'BEGIN{FS="subject:"}{print $1 $2}'`
			
				rm $REPO_ROOT/p.txt
			
				if [ -z $NUMBER ]; then
					LINK="not in gerrit"
					SUBJECT=$SUBJECT_LOCAL
				else
					LINK="http://android.intel.com:8080/#/c/$NUMBER/"
				fi	

				echo "$LINK  $SUBJECT"
			else
				echo "Patch with no Change-id"
			fi
			done
		echo ""
		cd $REPO_ROOT	
	done

}

#main state machine
main ()
{
	while [ ! -z "$1" ]; do
		debug_print "main $1"
		case $1 in
		-vv)		MODE=0;;
		-check)		MODE=1;;
		-apply)		MODE=2;;
		-get)		MODE=4;;
		-show)		MODE=5;;
		-review)	MODE=6;;
		-reset)		repo_reset;;
		-status)	repo_status;;
		-brcm)		set_brcm;;
		-f)		read_from_file $2;exit;;
		-DEBUG)		DEBUG=1;;
		-user)		set_user $2; shift;;
		-help)		usage;exit;;
		--help)		usage;exit;;
		*) run_action $1;;
        	esac
        	shift
	done
}

if [ -z "$1"  ]; then
	usage;exit 1;
fi
sanity;
main "$@";
