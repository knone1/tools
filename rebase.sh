OLD=/home/axelh/RELEASES/R3/WW50
NEW=/home/axelh/RELEASES/R3/2012_WW20
CUR_DIR=$PWD
is_diff=0;



find_files()
{
	if [ -e step1.txt ]; then
		rm step1.txt
	fi
	cd $NEW
	#list all files on the new repo
	find . -name '*.cpp' -or -name '*.java' -or -name '*.[chxsS]' >step1.txt
	cd $CUR_DIR
}

sort_new_files()
{
	if [ -e step1.1.txt ]; then
		rm step1.1.txt
	fi
	if [ -e new.txt ]; then
		rm new.txt
	fi
	while read line
	do
		#if file exists on old repo its not new
		if [ -e $OLD/$line ];then
			echo $line >> step1.1.txt
		else
			echo $line >> step1_new.txt
		fi
	done <step1.txt
	rm step1.txt
	mv step1.1.txt step1.txt
}

compare2()
{
	FILE=$1
	is_diff=`diff $OLD/$FILE $NEW/$FILE`
	if [ -z "$is_diff" ]; then
		is_diff=0
	else
		is_diff=1
	fi
}

compare_all()
{
	if [ -e step2.txt ]; then
		rm step2.txt
	fi
	if [ ! -e step1.txt ]; then
		echo "No files for compare."	
	fi

	while read line
	do
		compare2 $line
		#list files that changed
		if [ $is_diff -eq 1 ]; then
			echo $line >> step2.txt
		fi
	done < step1.txt
}

separate_dir_form_file()
{
	if [ -e step3.txt ]; then
		rm step3.txt
	fi
	if [ ! -e step2.txt ]; then
		echo "error: step2.txt does not exist"
	fi
	cat step2.txt |awk '
	BEGIN{
       		 FS="/"
	}
	END{}
	{
		printf "."
		for (i=1;i<NF;i++){
			printf "/"$i
		}
		printf " "$i
		printf "\n"
	}

	' > ./step3.txt
}

find_changed_by_intel()
{
	if [ -e step4.1.txt ]; then
		rm step4.1.txt
	fi
	
	if [ -e step4.2.txt ]; then
		rm step4.2.txt
	fi

	if [ ! -e step3.txt ]; then
		echo "error: step3.txt does not exist"
	fi

	while read line
	do
		DIR=`echo $line|awk 'BEGIN{FS=" "}{printf $1}'`
		FILE=`echo $line|awk 'BEGIN{FS=" "}{printf $2}'`
		
		cd $NEW/$DIR

		#search for intel.com en the latest commit
		is_intel=`git log -1 $FILE |grep intel.com`
		if [ -n "$is_intel" ];then
			is_intel=1
			echo $DIR"/"$FILE $is_intel >> $CUR_DIR/step4.1.txt
		else
			is_intel=0
			echo $DIR"/"$FILE $is_intel >> $CUR_DIR/step4.2.txt
		fi

		cd $CUR_DIR
	done <step3.txt
}

echo "********* STEP 1 - find_files"
find_files
echo "********* STEP 1.1 - sort__new_files"
sort_new_files
echo "********* STEP 2 - compare_all"
compare_all
echo "********* STEP 3 - separate_dir_form_file"
separate_dir_form_file
echo "********* STEP 4 - find_changed_by_intel"
find_changed_by_intel


