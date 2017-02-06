Tipping
-------

[![Pledgie !](https://pledgie.com/campaigns/32702.png)](https://pledgie.com/campaigns/32702)
[![Tip with Altcoins](https://raw.githubusercontent.com/Miouyouyou/Shapeshift-Tip-button/9e13666e9d0ecc68982fdfdf3625cd24dd2fb789/Tip-with-altcoin.png)](https://shapeshift.io/shifty.html?destination=16zwQUkG29D49G6C7pzch18HjfJqMXFNrW&output=BTC)
[![Tip with Bitcoins](https://raw.githubusercontent.com/Miouyouyou/miouyouyou.github.io/master/img/btc-icon.png)](bitcoin:16zwQUkG29D49G6C7pzch18HjfJqMXFNrW)

About
-----

This is a working patched 4.10-rc7 kernel with [Mali r15p0 Kernel drivers](http://malideveloper.arm.com/resources/drivers/open-source-mali-midgard-gpu-kernel-drivers/), using the torvalds branch as a basis. This also integrate patches from Willy Tarreau, making possible to get better performances from the board. [More informations in this thread](https://forum.mqmaker.com/t/miqi-based-build-farm-finally-up-and-running/605).

Currently this kernel has been tested sucessfully with the [Firefly's Mali User-space r12p0 drivers for fbdev and wayland](http://malideveloper.arm.com/resources/drivers/arm-mali-midgard-gpu-user-space-drivers/#mali-user-space-driver-r12p0-mali-t760-gnulinux), using the [OpenGL ES 3.1 samples of the Mali OpenGL ES SDK](http://malideveloper.arm.com/resources/sdks/opengl-es-sdk-for-linux/). Pure DRM OpenGL was also tested successfully with these drivers, using [this patched gl2mark](https://github.com/Miouyouyou/glmark2).

X11 drivers were not tested successfully however.

The kernel was compiled using the following procedure :
```bash
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

export KERNEL_BRANCH=v4.10-rc7
export KERNEL_VERSION=4.10.0-rc7
export MYY_VERSION=RockMyyX-rc+
export MALI_VERSION=r15p0-00rel0

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
0005-Post-Mali-UMP-integration.patch
0006-ARM-dts-rockchip-fix-the-regulator-s-voltage-range-o.patch
0007-ARM-dts-rockchip-fix-the-MiQi-board-s-LED-definition.patch
0008-ARM-dts-rockchip-add-the-MiQi-board-s-fan-definition.patch
0009-ARM-dts-rockchip-add-support-for-1800-MHz-operation-.patch
0010-clk-rockchip-add-all-known-operating-points-to-the-a.patch
0011-ARM-dts-rockchip-miqi-add-turbo-mode-operating-point.patch
0012-arm-dts-Adding-and-enabling-VPU-services-addresses-f.patch
0013-Export-rockchip_pmu_set_idle_request-for-out-of-tree.patch
0014-Adaptation-of-Shawn-Lin-s-patch-muting-the-MMC-drive.patch
"
export MALI_PATCHES="
0001-Midgard-daptation-to-Linux-4.10.0-rcX-signatures.patch
0002-UMP-Adapt-get_user_pages-calls.patch
0003-Renamed-Kernel-DMA-Fence-structures-and-functions.patch
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

# Download and apply the various kernel and Mali kernel-space driver patches
download_and_apply_patches $KERNEL_PATCHES_FOLDER_URL $KERNEL_PATCHES
download_and_apply_patches $MALI_PATCHES_FOLDER $MALI_PATCHES

# Get the configuration file and compile the kernel
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper
wget -O .config "$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/boot/config-$KERNEL_VERSION$MYY_VERSION"
make rk3288-miqi.dtb zImage modules -j5
```

This procedure was stored in the **[GetPatchAndCompileKernel.sh](./GetPatchAndCompileKernel.sh)** file and can be run like this :
```bash
sh GetPatchAndCompileKernel.sh
```

You will need compiling tools, **git**, **wget** and **find** in order to execute this procedure successfully.

The patches applied are stored in the **[patches/](./patches/)** folder.

To install this kernel, copy the **zImage** and the **rk3288-miqi.dtb** file in your boot partition.
Note that if you have access to U-boot through a serial console AND your MiQi is powered through your USB computer, you can access the whole eMMC like a USB memory stick using the following command :
```
ums 0 mmc 1
```

TODO
----

- [x] Document how to use the generated kernel and boot it
- [x] Add the [Open Source Kernel-space Mali Midgard drivers](http://malideveloper.arm.com/resources/drivers/open-source-mali-midgard-gpu-kernel-drivers/)
- [ ] Add [gator](https://github.com/ARM-software/gator) (Generates lock-ups)
- [ ] Document how to use [DS-5 : Streamline](https://developer.arm.com/products/software-development-tools/ds-5-development-studio/streamline/overview) to analyse OpenGL ES 2.x/3.x programs running on MiQi boards using such kernels. (Generates lock-ups)
- [ ] Integrating Rockchip VPU code (In progress)



