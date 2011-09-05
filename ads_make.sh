
MYDROID=/home/axel/androidcode
cd $MYDROID
rm -rf myfs
mkdir myfs
cd myfs
cp -Rfp $MYDROID/out/target/product/zoom2/root/* .
cp -Rfp $MYDROID/out/target/product/zoom2/system/ .
cp -Rfp $MYDROID/out/target/product/zoom2/data/ .
mv init.rc init.rc.bak
cp -Rfp $MYDROID/vendor/ti/zoom2/omapzoom2-mmc.rc init.rc

cd ..
rm ~/export/myfs 
cp ./myfs ~/export -rf