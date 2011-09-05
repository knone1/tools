if [ $2 == "2" ];then
	rm -rf ~/bin/uImage2
	ln -s $PWD/$1/uImage ~/bin/uImage2
	rm -f ~/export/fslink2/*.ko
	cp $PWD/$1/*.ko ~/export/fslink2/
fi
if [ $2 == "1" ];then
	rm -rf ~/bin/uImage
	ln -s $PWD/$1/uImage ~/bin/uImage
	rm -f ~/export/fslink/*.ko
	cp $PWD/$1/*.ko ~/export/fslink/
fi