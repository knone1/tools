NEW=/home/axelh/RELEASES/R3/2012_WW22
CUR_DIR=$PWD
is_diff=0;

find_files()
{
	if [ -e 2step1.txt ]; then
		rm 2step1.txt
	fi
	cd $NEW
	#list all files on the new repo
	find . -name '.git' > $CUR_DIR/2step1.txt
	cd $CUR_DIR
}

separate_dir_form_file()
{
	if [ -e $CUR_DIR/2step2.txt ]; then
		rm $CUR_DIR/2step2.txt
	fi
	if [ ! -e $CUR_DIR/2step1.txt ]; then
		echo "error: step1.txt does not exist"
	fi
	cat $CUR_DIR/2step1.txt |awk '
	BEGIN{
       		 FS="/"
	}
	END{}
	{
		printf "."
		for (i=2;i<NF;i++){
			printf "/"$i
		}
		printf "\n"
	}

	' > $CUR_DIR/2step2.txt
}

find_changed_by_intel()
{
	echo "find_changed_by_intel"
	if [ ! -e $CUR_DIR/2step2.txt ]; then
		echo "error: 2step2.txt does not exist"
	fi

	if [ -e $CUR_DIR/2step4.txt ]; then
		rm 2step4.txt
	fi
	
	while read line
	do
		cd $NEW/$line
		echo " " >> $CUR_DIR/2step4.txt
		echo " " >> $CUR_DIR/2step4.txt
		echo "GIT PROJECT:" $line >> $CUR_DIR/2step4.txt
		echo $line
		n_intel_commits=0;
		total_commits=0;
		is_intel=1;
		is_error=0;
		#search for intel.com en the latest commit
		while [ $total_commits -lt 600 -a $is_error -eq 0 ]; do
			commit=`git log HEAD~$total_commits -1 2>&1`
			is_intel=`echo $commit|grep intel.com`
			is_error=`echo $commit|grep fatal|grep ambiguous`
			is_merge=`echo $commit|grep Automerger`		
			if [ -n "$is_error" ];then
				is_error=1
			else
				is_error=0
			fi
			if [ -n "$is_merge" ];then
				is_error=1
			fi
		
			if [ -n "$is_intel" ];then
				is_intel=1
				f=`git log --oneline HEAD~$total_commits -1`
				echo $f >> $CUR_DIR/2step4.txt
				n_intel_commits=$[$n_intel_commits+1]

				echo $n_intel_commits
			else
				is_intel=0
				if [ $total_commits -eq 0 ];then
					is_error=1
				fi
			fi
			total_commits=$[$total_commits+1]
			
		done
		echo "TOTAL PATCHES" $n_intel_commits >> $CUR_DIR/2step4.txt
		echo "TOTAL PATCHES" $n_intel_commits
		cd $CUR_DIR
	done < $CUR_DIR/2step2.txt
}

find_files
separate_dir_form_file
find_changed_by_intel

