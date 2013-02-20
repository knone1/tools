DAY=`date|awk '{print $3}'`
MONTH=`date|awk '{print $2}'`
HOUR=`date|awk '{print $4}'|awk 'BEGIN{FS=":"}{print $1}'`
NAME=$MONTH$DAY$HOUR


repo forall -c "git am --abort"
repo abandon main
repo forall -c ".;git_checkout.sh main"
repo sync -j8

repo start  $NAME --all

rm -rf ./pub
mkdir $NAME

#Axel switch module
getPatch.sh -apply 87303 87302 86590 87307 87341 86590 87387 88651


repo overview -b > $DATE/overview.txt

source ./build/envsetup.sh

lunch lexington-eng
make -j8 flashfiles
make -j8 blank_flashfiles

lunch ctpscaleht-eng
make -j8 flashfiles
make -j8 blank_flashfiles

lunch blackbay_bcm-eng
make -j8 flashfiles
make -j8 blank_flashfiles


