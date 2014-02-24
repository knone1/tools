


#VERSION="TEGRA_C13374A"
VERSION="TEGRA_C13481B"

FILE=".getconfig_$VERSION"
BUILDDIR="/home/mmes/build"
BUILDFILE="~/tools/build37.sh "

#entrynav-src




# create the .getconfig file with pkg name and version
set_pkg_config()
{
	echo ""
	echo "################################################################################"
	echo "Enter set_pkg_config"
	rm $FILE
	get_known_pkg;
	get_unknown_pkg;
}

#use apt get to download the pkg. wget does not seem to work with SSL?
download_pkgs()
{
	echo ""
	echo "################################################################################"
	echo "Enter download_pkgs"
	while read line; do
		PKGNAME=`echo $line|awk 'BEGIN{FS=","}{printf $1}'`
		PKGVERS=`echo $line|awk 'BEGIN{FS=","}{printf $2}'`

		#this is the file name when downloading with apt
		PKGVERS2=`echo $PKGVERS|sed 's/[_]/%5f/g'`
		FILENAME=`echo $PKGNAME"_"$PKGVERS2"_i386.deb"`

		APTCMD="$PKGNAME=$PKGVERS"
		echo "### Processing... $PKGNAME $PKGVERS $FILENAME"
			
		sudo rm /var/cache/apt/archives/$PKGNAME*
		#remove partial shit
		sudo rm /var/cache/apt/archives/partial/*

		if [ ! -e "$FILENAME" ]; then
			echo "### Downloading... $PKGNAME $PKGVERS $FILENAME"
			sudo apt-get install $APTCMD -y --force-yes -d --reinstall
			sudo chmod 777 /var/cache/apt/archives/$PKGNAME*		
			sudo mv /var/cache/apt/archives/$PKGNAME* .
		else
			echo $FILENAME " found!"
		fi

		echo "### Installing...  $FILENAME"
		sudo dpkg -i $FILENAME

	done < $FILE
}

remove_current_pkg()
{
	echo ""
	echo "################################################################################"
	echo "Enter remove_current_pkg"
	tac  $FILE > ./.tmp.txt
	while read line; do
		
		PKGNAME=`echo $line|awk 'BEGIN{FS=","}{printf $1}'`
		PKGVERS=`echo $line|awk 'BEGIN{FS=","}{printf $2}'`

		echo "### Removing...  $PKGNAME $PKGVERS"
		sudo dpkg -r $PKGNAME

	done < ./.tmp.txt
	rm ./.tmp.txt
}

install_new_pkg()
{
	echo ""
	echo "################################################################################"
	echo "Enter install_new_pkg"
	while read line; do
		PKGNAME=`echo $line|awk 'BEGIN{FS=","}{printf $1}'`
		PKGVERS=`echo $line|awk 'BEGIN{FS=","}{printf $2}'`
		echo "### Installing...  $PKGNAME $PKGVERS"
		sudo dpkg -i $PKGNAME*.deb

		echo "Installed pkg is..."
		dpkg -l |grep $PKGNAME
	done < $FILE
}

show_deps()
{
	echo ""
	echo "################################################################################"
	echo "Enter install_new_pkg"
	while read line; do
		PKGNAME=`echo $line|awk 'BEGIN{FS=","}{printf $1}'`
		PKGVERS=`echo $line|awk 'BEGIN{FS=","}{printf $2}'`
		
		DEP=`apt-cache show $PKGNAME|grep -A 1 $PKGVERS|grep "Depends"`
		echo "$PKGNAME... $DEP"
		
	done < $FILE

}


compile()
{
	echo ""
	echo "################################################################################"
	echo "Enter Compile"
	cd ~
	rm -rf $BUILDDIR
	mkdir $BUILDDIR
	cd  $BUILDDIR
	$BUILDFILE
	make all
}


compile

exit
rm $FILE
get_unknown_pkg
get_known_pkg
remove_current_pkg
download_pkgs
exit



