repo sync -j4; 

lunch ctpscaleht-eng;
make -j8 flashfiles;
make -j8 blank_flashfiles; 

lunch lexington-eng;
make -j8 flashfiles;
make -j8 blank_flashfiles;

lunch blackbay_bcm-eng;
make -j8 flashfiles;
make -j8 blank_flashfiles;


