# Get the kernel
git clone --depth 1 --branch v4.9-rc4 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' &&
cd linux
# Download, prepare and copy the Mali Kernel-Space drivers. 
# Some TGZ are AWFULLY packaged...
export DRIVER_VERSION=r14p0-01rel0
wget "http://malideveloper.arm.com/downloads/drivers/TX011/$DRIVER_VERSION/TX011-SW-99002-$DRIVER_VERSION.tgz" &&
tar zxvf TX011-SW-99002-$DRIVER_VERSION.tgz &&
cd TX011-SW-99002-$DRIVER_VERSION &&
find . -type 'f' -exec chmod 0644 {} ';' &&
find . -type 'd' -exec chmod 0755 {} ';' &&
find . -name 'sconscript' -exec rm {} ';' &&
rm -r 'driver/product/kernel/patches' 'driver/product/kernel/license.txt' &&
cp -r driver/product/kernel/drivers/gpu/arm ../drivers/gpu/ &&
cd .. &&
rm -r TX011-SW-99002-$DRIVER_VERSION TX011-SW-99002-$DRIVER_VERSION.tgz
# Apply the Rockchip DRM, Rockchip fbdev, RK3288 DTS and
# Kconfig/Makefile patches used to enable the compilation of the
# Mali driver
export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=master
wget https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/patches/kernel-4.9-rc4/0001-Rockchip-DRM-and-Framebuffer-patches-from-ARM-softwa.patch &&
wget https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/patches/kernel-4.9-rc4/0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch &&
wget https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/patches/kernel-4.9-rc4/0003-Post-Mali-Kernel-device-drivers-modifications.patch
export PATCHES="0001-Rockchip-DRM-and-Framebuffer-patches-from-ARM-softwa.patch 0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch 0003-Post-Mali-Kernel-device-drivers-modifications.patch"
git apply $PATCHES &&
rm $PATCHES
unset PATCHES
# Apply a patch to the Mali Midgard driver that adapt the
# get_user_pages calls to the new signature.
wget https://raw.githubusercontent.com/$GITHUB_REPO/$GIT_BRANCH/patches/Mali/0001-Adapt-get_user_pages-calls-to-use-the-new-calling-pr.patch &&
git apply 0001-Adapt-get_user_pages-calls-to-use-the-new-calling-pr.patch &&
rm 0001-Adapt-get_user_pages-calls-to-use-the-new-calling-pr.patch
# Get the configuration file and compile the kernel
export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-
make mrproper &&
wget -O .config 'https://raw.githubusercontent.com/Miouyouyou/MyyQi/master/boot/config-4.9.0-rc4MyaMya%2B' &&
make rk3288-miqi.dtb zImage modules -j5
# Kernel compiled
# This will just copy the kernel files and libraries in /tmp
# This part is only useful if you're cross-compiling the kernel, of course
# mkdir /tmp/MyyQi &&
# mkdir /tmp/MyyQi/boot &&
# make INSTALL_MOD_PATH=/tmp/MyyQi modules_install &&
# make INSTALL_PATH=/tmp/MyyQi/boot install

