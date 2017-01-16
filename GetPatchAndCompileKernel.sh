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

export KERNEL_BRANCH=v4.9
export KERNEL_VERSION=4.9.0
export MYY_NAME=MyyMyy+
export MALI_VERSION=r15p0-00rel0

export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=v4.9

export BASE_FILES_URL=https://raw.githubusercontent.com
export PATCHES_FOLDER_URL=$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/patches
export KERNEL_PATCHES_FOLDER_URL=$PATCHES_FOLDER_URL/kernel/$KERNEL_BRANCH
export MALI_PATCHES_FOLDER=$PATCHES_FOLDER_URL/Mali/$MALI_VERSION

export MALI_PATCHES="
0001-Adapt-get_user_pages-calls-to-use-the-new-calling-pr.patch
0002-Adapt-the-UMP-code-to-new-calls.patch
"
export KERNEL_PATCHES="
0001-Rockchip-DRM-and-Framebuffer-patches-from-ARM-softwa.patch
0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch
0003-Post-Mali-Kernel-device-drivers-modifications.patch
0004-Add-the-Mali-Unified-Memory-Provider-to-the-kernel.patch
0005-ARM-dts-rockchip-fix-the-regulator-s-voltage-range-o.patch
0006-ARM-dts-rockchip-fix-the-MiQi-board-s-LED-definition.patch
0007-ARM-dts-rockchip-add-the-MiQi-board-s-fan-definition.patch
0008-ARM-dts-rockchip-add-support-for-1800-MHz-operation-.patch
0009-clk-rockchip-add-all-known-operating-points-to-the-a.patch
0010-ARM-dts-rockchip-miqi-add-turbo-mode-operating-point.patch
"

# Get the kernel
git clone --depth 1 --branch $KERNEL_BRANCH 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' &&
cd linux

export SRC_DIR=$PWD

# Download, prepare and copy the Mali Kernel-Space drivers. 
# Some TGZ are AWFULLY packaged with everything having 0777 rights.

wget "http://malideveloper.arm.com/downloads/drivers/TX011/$MALI_VERSION/TX011-SW-99002-$MALI_VERSION.tgz" &&
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

# Apply the Rockchip DRM, Rockchip fbdev, RK3288 DTS and
# Kconfig/Makefile patches used to enable the compilation of the
# Mali driver

download_and_apply_patches $KERNEL_PATCHES_FOLDER_URL $KERNEL_PATCHES
download_and_apply_patches $MALI_PATCHES_FOLDER $MALI_PATCHES

# Get the configuration file and compile the kernel
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper
wget -O .config "$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/boot/config-$KERNEL_VERSION$MYY_NAME"
make rk3288-miqi.dtb zImage modules -j5

# Kernel compiled
# This will just copy the kernel files and libraries in /tmp
# This part is only useful if you're cross-compiling the kernel, of course
# mkdir /tmp/MyyQi &&
# mkdir /tmp/MyyQi/boot &&
# mkdir /tmp/MyyQi/usr &&
# make INSTALL_MOD_PATH=/tmp/MyyQi modules_install &&
# make INSTALL_PATH=/tmp/MyyQi/boot install &&
# make INSTALL_HDR_PATH=/tmp/MyyQi/usr headers_install
# cp arch/arm/boot/zImage /tmp/MyyQi/boot
# cp arch/arm/boot/dts/rk3288-miqi.dtb /tmp/MyyQi/boot

