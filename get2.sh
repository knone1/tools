DOWNDIR="/home/mmes/get"
FILE="get.txt"
PSW="axel123"

#BUILDSCRIPT="/home/mmes/tools/build37.sh"
BUILDSCRIPT="/home/mmes/tools/build.sh"
BUILDDIR="/home/mmes/build"

DEBUG=0
FORCE=0

#REPO="ubuntu-bins-pu0314"
REPO="ubuntu-bins-pu0714"

TESTCONNFILE="mmbp-examples-wrlinux-layers-B2.1.0.deb"
TESTCONNURL="https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/m"
#
# pkg table {<pkg name>,<url>,<is release version>}
#
SITE="
arm-linux-kernel-entrynav,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/a,1
arm-rootfs-entrynav,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/a,1
arm-sysroot-entrynav,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/a,1
entrynav-layers,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/e,1
entrynav,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/e,1
wrlinux-mmbp,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/w,0
arm-host-tools-mmbp,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/a,0
arm-toolchain-mmbp,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/a,0
mmbp,https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/$REPO/pool/windriver/w,0
"
#linux-src-entrynav,https://ftpsrc:Concept.2@itpsmgit1.magnetimarelli.com/ftpsrc/outgoing/$REPO/pool/windriver/l,1
#entrynav-src,https://ftpsrc:Concept.2@itpsmgit1.magnetimarelli.com/ftpsrc/outgoing/$REPO/pool/windriver/e,1


debug_print() 
{
	if [ "$DEBUG" -eq 1 ]; then
		echo "DEBUG: " $1
	fi
}

usage()
{
	echo "usage:

Example uses:

download pkgs:
	get.sh -d TEGRA_C13405B
download and install:
	get.sh -d TEGRA_C13405B -i
download and install, force download if present:
	get.sh -f -d TEGRA_C13405B -i

download new, remove old, install new, build:
	get2.sh -d TEGRA_C13491B -r -i TEGRA_C13491B -b


-d)
--download)
	Download a pkgs into $FILE
	-d <VERSION>

-s)
--show)
	Show all available versions.

-i)
--install)
	install a particular version.
	-i <VERSION>

-r)
--remove)
	remove installed version.
	-r

-b)
--build)
	compile the build.
	-b

-c)
--check)
	Check if all pkgs are correctly installed.
	-c <VERSION>

-f)
--force)
	remove downloaded pkges. if present and download again.
	
-dg)
--debug)
	enable debug prints.

-h)
--help)
	show this help.
"
}

sanity()
{
	debug_print "Checking Sanity..."

	echo "Check if $DOWNDIR exists..."	
	if [ ! -e "$DOWNDIR" ]; then
		echo "Creating $DOWNDIR..."
		mkdir $DOWNDIR
	fi

	echo "Switch to $DOWNDIR..."
	cd $DOWNDIR

	echo "Bkp wgetrc..."
	mv ~/.wgetrc ./wgetrc.old
	echo "http_proxy=" > ./wgetrc.new
	echo "https_proxy=" >> ./wgetrc.new
	cp ./wgetrc.new ~/.wgetrc 

}

cleanup()
{
	debug_print "Restoring wgetrc..."
	cp ./wgetrc.old ~/.wgetrc
}

get_known_pkg()
{
        debug_print "Adding known pkgs to version file...$FILE"
	
        site_arr=($SITE)
        for i in ${site_arr[@]}; do
		KNOWN=`echo $i|awk 'BEGIN{FS=","}{printf $3}'`
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`

		if [ "$KNOWN" == "1" ]; then	
			URL=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
			debug_print "Added $PKG,$VERSION,$URL..."
			echo "$PKG,$VERSION,$URL" >> $FILE
		fi
        done
}

get_unknown_pkg()
{
	debug_print "Adding unknown pkgs to version file...$FILE"

        DEP=`apt-cache show entrynav-layers |grep -A 1 "Version: $VERSION"|grep "Depends"`

	if [ -z "$DEP" ]; then
		echo "Could not find all dependencies for $VERSION $DEP"
		exit 1
	fi	

	site_arr=($SITE)

        for i in ${site_arr[@]}; do
                COUNT=0;
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`

		debug_print "Searching for $PKG..."

		dep_arr=($DEP)
                for k in ${dep_arr[@]}; do
			debug_print " k=$k PKG=$PKG"

                        if [ "$k" == "$PKG" ]; then
				VER=`echo ${dep_arr[$((COUNT+2))]}`
 
                                #strip unwanted chars
                                VER=`echo $VER| sed 's/[\),]//g'`
				URL=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
			
				debug_print "Added $PKG,$VER,$URL..."
                                echo "$PKG,$VER,$URL" >> $FILE
                        fi
                        COUNT=$((COUNT+1))
                done
  
        done
}

generate_conf_file()
{
	debug_print "Creating pkg file $FILE..."
	rm $FILE
	get_known_pkg
	get_unknown_pkg
}

check_and_set_version()
{
	AVAILABLE=`apt-cache show entrynav|grep "Version"|awk '{printf $2"\n"}'`
	ISFOUND=0
	av_arr=($AVAILABLE)
	for i in ${av_arr[@]}; do
		if [ "$i" == "$1" ];then
			ISFOUND=1
		fi
	done

	if [ "$ISFOUND" == "0" ]; then
		echo "Version $1 not found... please check version or apt-get update "
		exit 1
	fi
	VERSION=$1
}

download()
{
	echo "Download..."
	cd $DOWNDIR

	echo "Check if we can download..."
	rm $TESTCONNFILE
	wget --no-check-certificate $TESTCONNURL/$TESTCONNFILE 
	if [ ! -e "$TESTCONNFILE" ]; then
		echo "Could not download test file..."
		exit
	fi

	check_and_set_version $1
	generate_conf_file

	WORK=`cat $FILE`
	debug_print "WORK = $WORK"
	WORK_ARR=($WORK)
	
	for i in ${WORK_ARR[@]}; do
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`
		VER=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
		URL=`echo $i|awk 'BEGIN{FS=","}{printf $3}'`
		FILE="$PKG-$VER.deb"
		debug_print "PKG=$PKG VER=$VER URL=$URL..."
		CMD="wget --no-check-certificate $URL/$PKG-$VER.deb"

		if [ "$FORCE" = "1" ]; then
			echo "-f is set, Removing $FILE..."
			rm $FILE
		fi

		if [ ! -e "$FILE" ];then
			echo "File not found $FILE, Downloading..."
			$CMD
		else 
			echo "File found $FILE, Continue..."
		fi
	done
}

show_versions()
{
	echo ""
	apt-cache show entrynav|grep "Version"|awk '{printf $2"\n"}'
}


remove()
{
	echo "Removing..."
	tac  $FILE > ./.tmp.txt
	WORK=`cat ./.tmp.txt`
	rm ./.tmp.txt

	debug_print "WORK = $WORK"
	WORK_ARR=($WORK)
	
	for i in ${WORK_ARR[@]}; do
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`
		VER=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
		FILE="$PKG-$VER.deb"
		echo "-$PKG..."
		echo $PSW |sudo -S dpkg -r $PKG
	done
}

install()
{
	echo ""
	echo "Installing..."

	check_and_set_version $1
	generate_conf_file

	WORK=`cat $FILE`
	debug_print "WORK = $WORK"
	WORK_ARR=($WORK)
	
	for i in ${WORK_ARR[@]}; do
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`
		VER=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
		FILE="$PKG-$VER.deb"
		echo "Check if $FILE exists.."
		if [ ! -e "$FILE" ];then
			echo "Pkg $FILE is not present... please download with -d"
			exit 1
		else
			echo "OK.."
		fi
	done

	for i in ${WORK_ARR[@]}; do
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`
		VER=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
		FILE="$PKG-$VER.deb"
		echo "+$FILE..."
		echo $PSW |sudo -S dpkg -i $FILE
	done
}

compile()
{
	INSTALL='dpkg -l|grep TEGRA|awk '{printf $2","$3"\n"}''
	install_arr=$(INSTALL)

	echo "Building..."
	echo "Removing builddir $BUILDDIR..."
	rm -rf $BUILDDIR
	echo "Creating $BUILDDIR..."
	mkdir $BUILDDIR
	cd $BUILDDIR
	echo "Run buildscript..."
	$BUILDSCRIPT
}

check()
{
	echo ""
	echo "Checking if $1 is correctly installed..."
	FAIL=0

	check_and_set_version $1
	generate_conf_file

	WORK=`cat $FILE`
	debug_print "WORK = $WORK"
	WORK_ARR=($WORK)
	for i in ${WORK_ARR[@]}; do
		PKG=`echo $i|awk 'BEGIN{FS=","}{printf $1}'`
		VER=`echo $i|awk 'BEGIN{FS=","}{printf $2}'`
		FILE="$PKG-$VER.deb"
		CURR_VER=`dpkg -s $PKG|grep "Version"|awk '{printf $2}'`
		if [ "$CURR_VER" != "$VER" ]; then
			echo "Pkg $PKG installed version is $CURR_VER but needed is $VER"
			FAIL=1
		fi

	done

	if [ "$FAIL" == "1" ]; then
		echo "Check failed!"
		exit 1
	else
		echo "Check passed! $1 installed correctly."
	fi
}

main ()
{
	debug_print "Main $@"
	sanity;

        while [ ! -z "$1" ]; do
                case $1 in
		-d)		download $2;;
		--download)	download $2;;

		-s)		show_versions;exit;;
		--show)		show_versions;exit;;

		-i)		install $2;;
		--install)	install $2;;

		-r)		remove $2;;
		--remove)	remove $2;;

		-b)		compile;;
		--build)	compile;;

		-c)		check $2;;
		--check)	check $2;;

		-f)		FORCE=1;;
		--force)	FORCE=1;;

		-dg)		DEBUG=1;;
		--debug)	DEBUG=1;;

		-h)		usage;exit;;
                --help)         usage;exit;;
        	
                esac
                shift
        done
	cleanup
}

main "$@";

