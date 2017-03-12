function download_patches {
	base_url=$1
	patches=${@:2}
	for patch in $patches; do
		wget $base_url/$patch ||
		{ echo "Could not download $patch"; exit 1; }
	done
}

function download_and_apply_patches {
	base_url=$1
	patches=${@:2}
	download_patches $base_url $patches
	git apply $patches
	rm $patches
}

export DTB_FILES="rk3288-miqi.dtb"

export KERNEL_BRANCH=v4.10
export KERNEL_VERSION=4.10.0
export MYY_VERSION=RockMyyX+
export MALI_VERSION=r16p0-00rel0
export MALI_BASE_URL=https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-midgard-gpu

export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=master

export BASE_FILES_URL=https://raw.githubusercontent.com
export PATCHES_FOLDER_URL=$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/patches
export KERNEL_PATCHES_FOLDER_URL=$PATCHES_FOLDER_URL/kernel/$KERNEL_BRANCH
export MALI_PATCHES_FOLDER=$PATCHES_FOLDER_URL/Mali/$MALI_VERSION

export KERNEL_PATCHES="
0001-Readaptation-of-Rockchip-DRM-patches-provided-by-ARM.patch
0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch
0003-Post-Mali-Kernel-device-drivers-modifications.patch
0004-Post-Mali-UMP-integration.patch
0005-ARM-dts-rockchip-fix-the-regulator-s-voltage-range-o.patch
0006-Adaptation-ARM-dts-rockchip-fix-the-MiQi-board-s-LED.patch
0007-Adaptation-ARM-dts-rockchip-add-the-MiQi-board-s-fan.patch
0008-ARM-dts-rockchip-add-support-for-1800-MHz-operation-.patch
0009-clk-rockchip-add-all-known-operating-points-to-the-a.patch
0010-Readapt-ARM-dts-rockchip-miqi-add-turbo-mode-operati.patch
0011-arm-dts-Adding-and-enabling-VPU-services-addresses-f.patch
0012-Export-rockchip_pmu_set_idle_request-for-out-of-tree.patch
"

export MALI_PATCHES="
0001-Midgard-daptation-to-Linux-4.10.0-rcX-signatures.patch
0002-UMP-Adapt-get_user_pages-calls.patch
0003-Renamed-Kernel-DMA-Fence-structures-and-functions.patch
0004-Few-modifications-after-v4.11-headers-and-signatures.patch
"

# Get the kernel

git clone --depth 1 --branch v4.11-rc1 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' &&
cd linux

export SRC_DIR=$PWD

# Download, prepare and copy the Mali Kernel-Space drivers. 
# Some TGZ are AWFULLY packaged with everything having 0777 rights.

wget "$MALI_BASE_URL/TX011-SW-99002-$MALI_VERSION.tgz" &&
tar zxvf TX011-SW-99002-$MALI_VERSION.tgz &&
cd TX011-SW-99002-$MALI_VERSION &&
find . -type 'f' -exec chmod 0644 {} ';' && # Every file   should have -rw-r--r-- rights
find . -type 'd' -exec chmod 0755 {} ';' && # Every folder should have drwxr-xr-x rights
find . -name 'sconscript' -exec rm {} ';' && # Remove sconscript files. Useless.
cd driver/product/kernel &&
rm -r 'patches' 'license.txt' && # Remove the patches and GPL license file.
cp -r drivers/gpu/arm  $SRC_DIR/drivers/gpu/ && # Copy the Midgard code
cp -r drivers/base/ump $SRC_DIR/drivers/base/ && # Copy the Unified Memory Provider code
cp include/linux/ump*  $SRC_DIR/include/linux/ && # Copy the Unified Memory Provider headers.
cp include/linux/kds.h $SRC_DIR/include/linux/ && # Copy the Kernel Dependency System header ↑ (dependency)
cd $SRC_DIR &&
rm -r TX011-SW-99002-$MALI_VERSION TX011-SW-99002-$MALI_VERSION.tgz

# Download and apply the various kernel and Mali kernel-space driver patches
download_patches $KERNEL_PATCHES_FOLDER_URL $KERNEL_PATCHES
download_and_apply_patches $MALI_PATCHES_FOLDER $MALI_PATCHES

# Get the configuration file and compile the kernel
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper
wget -O .config "$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/boot/config-$KERNEL_VERSION$MYY_VERSION"
# make $DTB_FILES zImage modules -j5

# Kernel compiled
# This will just copy the kernel files and libraries in /tmp
# This part is only useful if you're cross-compiling the kernel, of course
# export INSTALL_MOD_PATH=/tmp/MyyQi
# export INSTALL_PATH=/tmp/MyyQi/boot
# export INSTALL_HDR_PATH=/tmp/MyyQi/usr
# mkdir -p $INSTALL_MOD_PATH $INSTALL_PATH $INSTALL_HDR_PATH
# make modules_install &&
# make install &&
# make INSTALL_HDR_PATH=$INSTALL_HDR_PATH headers_install && # This command IGNORES predefined variables
# cp arch/arm/boot/zImage $INSTALL_PATH &&
# cp arch/arm/boot/dts/rk3288-miqi.dtb $INSTALL_PATH

