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


remove_if_present()
{
	if [ -e $1 ]; then
		rm $1
	fi
}


sum_check=0;
check_and_add()
{
	if [ -n "$1" ]; then
		if [ "$1" != "is_cws" ]; then
			sum_check=$[$sum_check+1]	
		fi
		echo "$3" >> $CUR_DIR/"$2".txt
	fi	


}

find_changed_by_intel()
{
	echo "find_changed_by_intel"
	if [ ! -e $CUR_DIR/2step2.txt ]; then
		echo "error: 2step2.txt does not exist"
	fi

	remove_if_present $CUR_DIR/2step4.txt
	remove_if_present $CUR_DIR/is_bt.txt
	remove_if_present $CUR_DIR/is_nfc.txt
	remove_if_present $CUR_DIR/is_wifi.txt
	remove_if_present $CUR_DIR/is_pnp.txt
	remove_if_present $CUR_DIR/is_cws.txt
	remove_if_present $CUR_DIR/is_widi.txt
	remove_if_present $CUR_DIR/is_gps.txt
	remove_if_present $CUR_DIR/is_intel.txt

#	cat $CUR_DIR/2step2.txt|grep -v linux-2.6 > $CUR_DIR/2step2B.txt 
#	mv  $CUR_DIR/2step2B.txt $CUR_DIR/2step2.txt
	
	n_line=0;
	n_totalLines=`grep -c "" $CUR_DIR/2step2.txt`
	while read line
	do
		n_line=$[$n_line+1]
		echo $line $n_line"/"$n_totalLines
				
		cd $NEW/$line
		echo " " >> $CUR_DIR/2step4.txt
		echo " " >> $CUR_DIR/2step4.txt
		echo "GIT PROJECT:" $line >> $CUR_DIR/2step4.txt
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
				is_bt=`echo $commit|egrep -i "julienx.gros|beldie"`
				is_nfc=`echo $commit|egrep -i "rebraca|niciarz"`
				is_wifi=`echo $commit|egrep -i "cesco|regairaz|jeremie|bachot|tricot|trivelly|sinigaglia"`
				is_pnp=`echo $commit|egrep -i "isaksen|zayet|fiat|haslam"`
				is_cws=`echo $commit|egrep -i "champciaux|zurmely"`
				is_widi=`echo $commit|egrep -i "rajneeshx.chowdhury|miguel.verdu|juha.alanen|mamatha.balguri|karthik.veeramani|fabien.marotte" |egrep -i -v "libcamera"`
				is_gps=`echo $commit|egrep -i "jeromex.pantaloni|fabien.peix|fabienx.peix"`
				is_fm="";
				sum_check=0;
			

				f=`git log --oneline HEAD~$total_commits -1`
				f="$line $f"
				is_bt+=`echo $f|egrep -i "bt|bluetooth"`
				is_nfc+=`echo $f|egrep -i "nfc|smartcard"`
				is_wifi+=`echo $f|egrep -i "wifi|wlan|wpa_supplicant_8|Tether"`
				is_widi+=`echo $f|egrep -i "widi"`
				is_gps+=`echo $f|egrep -i "gps|BOOTCLASSPATH"`
				is_fm+=`echo $f|egrep -i "fm"`				

				is_cws+=$is_bt;
				is_cws+=$is_nfc;
				is_cws+=$is_wifi;
				is_cws+=$is_widi;
				is_cws+=$is_gps;
				is_cws+=$is_fm;
				is_cws+=$is_pnp;
	
				if [	-n "$is_cws" -o \
					-n "$is_bt" -o \
					-n "$is_nfc" -o \
					-n "$is_wifi" -o \
					-n "$is_pnp" -o \
					-n "$is_cws" -o \
					-n "$is_widi" -o \
					-n "$is_fm" -o \
					-n "$is_gps" ]; then

					
					echo $f
					
				fi
				check_and_add "$is_bt" "is_bt" "$f"
				check_and_add "$is_wifi" "is_wifi" "$f"
				check_and_add "$is_nfc" "is_nfc" "$f"
				check_and_add "$is_pnp" "is_pnp" "$f"
			#	check_and_add "$is_cws" "is_cws" "$f"
#				if [ -n "$is_cws" ]; then
					check_and_add "$is_widi" "is_widi" "$f"
					check_and_add "$is_gps" "is_gps" "$f"
#				fi
				check_and_add "$is_fm" "is_fm" "$f"
				if [ "$sum_check" -gt 1 ];then
					echo $f >> $CUR_DIR/is_conflict.txt	
				fi
				
				if [ -n $is_cws ]; then
					echo $f >> $CUR_DIR/is_cws.txt
				fi
				echo $f >> $CUR_DIR/is_intel.txt

				echo $f >> $CUR_DIR/2step4.txt
				n_intel_commits=$[$n_intel_commits+1]

#				echo $n_intel_commits
			else
				is_intel=0
				if [ $total_commits -eq 0 ];then
					is_error=1
				fi
			fi
			total_commits=$[$total_commits+1]
			
		done
		echo "TOTAL PATCHES" $n_intel_commits >> $CUR_DIR/2step4.txt
		cd $CUR_DIR
	done < $CUR_DIR/2step2.txt
}



#find_files
#separate_dir_form_file
#find_changed_by_intel
get_author()
{
	remove_if_present $CUR_DIR/is_authors.txt
	while read line;do
	test1="";
	commit=""
	test1=`echo $line|awk '
	BEGIN{FS=" "}{printf $1}'`
	commit=`echo $line|awk '
	BEGIN{FS=" "}{printf $2}'`


	echo $test1
	cd $NEW/$test1
	test2=`git log $commit -1|grep Author`
	echo $test2 >> $CUR_DIR/is_authors.txt
	cd  $CUR_DIR

	done < $CUR_DIR/is_intel.txt

}

get_author
