Tipping
-------

[![Pledgie !](https://pledgie.com/campaigns/32702.png)](https://pledgie.com/campaigns/32702)
[![Tip with Altcoins](https://shapeshift.io/images/shifty/small_light_altcoins.png)](https://shapeshift.io/shifty.html?destination=16zwQUkG29D49G6C7pzch18HjfJqMXFNrW&output=BTC)

About
-----

This is a working patched 4.10-rc3 kernel with [Mali r15p0 Kernel drivers](http://malideveloper.arm.com/resources/drivers/open-source-mali-midgard-gpu-kernel-drivers/), using the torvalds branch as a basis.

Currently this kernel has been tested sucessfully with the [Firefly's Mali User-space r12p0 drivers for fbdev and wayland](http://malideveloper.arm.com/resources/drivers/arm-mali-midgard-gpu-user-space-drivers/#mali-user-space-driver-r12p0-mali-t760-gnulinux), using the [OpenGL ES 3.1 samples of the Mali OpenGL ES SDK](http://malideveloper.arm.com/resources/sdks/opengl-es-sdk-for-linux/).

X11 drivers were not tested successfully however.

The kernel was compiled using the following procedure :
```bash
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
export MALI_VERSION=r15p0-00rel0

export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=master

export BASE_FILES_URL=https://raw.githubusercontent.com
export PATCHES_FOLDER_URL=$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/patches
export KERNEL_PATCHES_FOLDER_URL=$PATCHES_FOLDER_URL/kernel/$KERNEL_VERSION
export MALI_PATCHES_FOLDER=$PATCHES_FOLDER_URL/Mali/$MALI_VERSION

git clone --depth 1 --branch $KERNEL_VERSION 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' &&
cd linux

export SRC_DIR=$PWD

# Download, prepare and copy the Mali Kernel-Space drivers. 
# Some TGZ are AWFULLY packaged with everything having 0777 rights.

wget "http://malideveloper.arm.com/downloads/drivers/TX011/$MALI_VERSION/TX011-SW-99002-$MALI_VERSION.tgz" &&
tar zxvf TX011-SW-99002-$MALI_VERSION.tgz &&
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

download_and_apply_patches $MALI_PATCHES_FOLDER $PATCHES
unset PATCHES

# Get the configuration file and compile the kernel
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper
wget -O .config "$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/boot/config-4.10.0-rc3RockMyyX-rc+"
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
- [ ] Add [gator](https://github.com/ARM-software/gator)
- [ ] Document how to use [DS-5 : Streamline](https://developer.arm.com/products/software-development-tools/ds-5-development-studio/streamline/overview) to analyse OpenGL ES 2.x/3.x programs running on MiQi boards using such kernels.



