# Get the kernel

function download_and_apply_patches {
	base_url=$1
	patches=${@:2}
	for patch in $patches; do
		wget $base_url/$patch || 
		{ echo "Could not download $patch"; exit 1; }
	done
	git apply $patches
	rm $patches
}

export KERNEL_VERSION=v4.10-rc3
git clone --depth 1 --branch $KERNEL_VERSION 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' &&
cd linux

export SRC_DIR=$PWD

# Download, prepare and copy the Mali Kernel-Space drivers. 
# Some TGZ are AWFULLY packaged with everything having 0777 rights.
export MALI_VERSION=r15p0-00rel0
wget "http://malideveloper.arm.com/downloads/drivers/TX011/$MALI_VERSION/TX011-SW-99002-$MALI_VERSION.tgz" &&
tar zxvf $PATCHES_DIR/TX011-SW-99002-$MALI_VERSION.tgz &&
cd TX011-SW-99002-$MALI_VERSION &&
find . -type 'f' -exec chmod 0644 {} ';' &&
find . -type 'd' -exec chmod 0755 {} ';' &&
find . -name 'sconscript' -exec rm {} ';' &&
cd driver/product/kernel &&
rm -r 'patches' 'license.txt' &&
cp -r drivers/gpu/arm  $SRC_DIR/drivers/gpu/ &&
cp -r drivers/base/ump $SRC_DIR/drivers/base/ &&
cp include/linux/ump*  $SRC_DIR/include/linux/ &&
cp include/linux/kds.h $SRC_DIR/include/linux/ &&
cd $SRC_DIR &&
rm -r TX011-SW-99002-$MALI_VERSION TX011-SW-99002-$MALI_VERSION.tgz

# Apply the Rockchip DRM, Rockchip fbdev, RK3288 DTS and
# Kconfig/Makefile patches used to enable the compilation of the
# Mali driver
export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=master
export PATCHES_FOLDER_URL=https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/patches
export KERNEL_PATCHES_FOLDER_URL=$PATCHES_FOLDER_URL/kernel/$KERNEL_VERSION
#
## TODO : The following patterns should be rewritten as a function...
export PATCHES="
0001-Readaptation-of-Rockchip-DRM-patches-provided-by-ARM.patch
0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch
0003-Post-Mali-Kernel-device-drivers-modifications.patch
0004-mmc-Applied-Ziyuan-Xu-dw_mmc-patch.patch
0005-Post-Mali-UMP-integration.patch
"
download_and_apply_patches $KERNEL_PATCHES_FOLDER_URL $PATCHES
unset PATCHES

# Apply a patch to the Mali Midgard driver that adapt the
# get_user_pages calls to the new signature.
export PATCHES="
0001-Midgard-daptation-to-Linux-4.10.0-rcX-signatures.patch
0002-UMP-Adapt-get_user_pages-calls.patch
0003-Renamed-Kernel-DMA-Fence-structures-and-functions.patch
"
export MALI_PATCHES_FOLDER=$PATCHES_FOLDER_URL/Mali/$MALI_VERSION
download_and_apply_patches $MALI_PATCHES_FOLDER $PATCHES
unset PATCHES

# Get the configuration file and compile the kernel
git apply -v $PATCHES_DIR/patches/Mali/$MALI_VERSION/*
git apply -v $PATCHES_DIR/patches/kernel/$KERNEL_VERSION/*
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper
wget -O .config "https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/boot/config-4.10.0-rc3RockMyyX-rc+"
make rk3288-miqi.dtb zImage modules -j5

# Kernel compiled
# This will just copy the kernel files and libraries in /tmp
# This part is only useful if you're cross-compiling the kernel, of course
# mkdir /tmp/MyyQi &&
# mkdir /tmp/MyyQi/boot &&
# make INSTALL_MOD_PATH=/tmp/MyyQi modules_install &&
# make INSTALL_PATH=/tmp/MyyQi/boot install
# cp arch/arm/boot/zImage /tmp/MyyQi/boot
# cp arch/arm/boot/dts/rk3288-miqi.dtb /tmp/MyyQi/boot

