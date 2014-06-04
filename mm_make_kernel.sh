

cp entrynav_TEGRA_D14024A_kernel_config.cfg ./.config
make ARCH=arm oldconfig
make ARCH=arm  CROSS_COMPILE=/MM_BASE/arm/toolchain/toolchain/x86-linux2/bin/arm-cortex_a9-linux-gnueabi-
cp -rf ./arch/arm/boot ./boot_normal
cp entrynav_TEGRA_D14024A_kernel_config_with_taskstats.cfg ./.config
make ARCH=arm oldconfig
make ARCH=arm  CROSS_COMPILE=/MM_BASE/arm/toolchain/toolchain/x86-linux2/bin/arm-cortex_a9-linux-gnueabi-
cp -rf ./arch/arm/boot ./boot_with_taskstats



