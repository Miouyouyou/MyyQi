export ARCH=arm
export CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-

if [ -z ${MAKE_CONFIG+x} ]; then
  export MAKE_CONFIG=oldconfig
fi

export DTB_FILES="
rk3288-evb-act8846.dtb
rk3288-evb-rk808.dtb
rk3288-fennec.dtb
rk3288-firefly-beta.dtb
rk3288-firefly-reload.dtb
rk3288-firefly.dtb
rk3288-tinker.dtb
rk3288-miniarm.dtb
rk3288-miqi.dtb
rk3288-popmetal.dtb
rk3288-r89.dtb
rk3288-rock2-square.dtb
rk3288-veyron-brain.dtb
rk3288-veyron-jaq.dtb
rk3288-veyron-jerry.dtb
rk3288-veyron-mickey.dtb
rk3288-veyron-minnie.dtb
rk3288-veyron-pinky.dtb
rk3288-veyron-speedy.dtb
"

export KERNEL_SERIES=v4.12
export KERNEL_BRANCH=v4.12-rc6
export KERNEL_VERSION=4.12.0-rc6
export MYY_VERSION=-The-Twelve-MyyQi+
export MALI_VERSION=r17p0-01rel0
export MALI_BASE_URL=https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-midgard-gpu

export GITHUB_REPO=Miouyouyou/MyyQi
export GIT_BRANCH=master

export BASE_FILES_URL=https://raw.githubusercontent.com
export PATCHES_FOLDER_URL=$BASE_FILES_URL/$GITHUB_REPO/tree/$GIT_BRANCH/patches
export KERNEL_PATCHES_FOLDER_URL=$PATCHES_FOLDER_URL/kernel/$KERNEL_SERIES
export MALI_PATCHES_FOLDER=$PATCHES_FOLDER_URL/Mali/$MALI_VERSION

export KERNEL_PATCHES="
0001-Readaptation-of-Rockchip-DRM-patches-provided-by-ARM.patch
0002-Integrate-the-Mali-GPU-address-to-the-rk3288-and-rk3.patch
0003-Post-Mali-Kernel-device-drivers-modifications.patch
0004-Post-Mali-UMP-integration.patch
0005-ARM-dts-rockchip-fix-the-regulator-s-voltage-range-o.patch
0007-Adaptation-ARM-dts-rockchip-add-the-MiQi-board-s-fan.patch
0008-ARM-dts-rockchip-add-support-for-1800-MHz-operation-.patch
0009-clk-rockchip-add-all-known-operating-points-to-the-a.patch
0010-Readapt-ARM-dts-rockchip-miqi-add-turbo-mode-operati.patch
0011-arm-dts-Adding-and-enabling-VPU-services-addresses-f.patch
0012-Export-rockchip_pmu_set_idle_request-for-out-of-tree.patch
0013-clk-rockchip-rk3288-prefer-vdpu-for-vcodec-clock-sou.patch
0014-ARMbian-RK3288-DTSI-changes.patch
0015-Enabling-Tinkerboard-s-Wifi-Third-tentative.patch
0016-Added-support-for-Tinkerboard-s-SPI-interface.patch
0017-Testing-DTS-changes-in-order-to-resolve-bug-8.patch
0018-Added-debug-messages-to-check-the-Bluetooth-Coexiste.patch
0019-Forward-port-of-the-Rockchip-GPIO-BT-RFKILL-system.patch
0020-Tinkerboard-DTS-Added-GPIO-Bluetooth-RFKILL-subsyste.patch
0100-First-Mali-integration-test-for-ASUS-Tinkerboards.patch
0200-The-Tinkerboard-DTS-file-maintained-by-TonyMac32-and.patch
0300-Adding-Mali-Midgard-and-VCodec-support-to-Firefly-RK.patch
"

export MALI_PATCHES="
0001-Midgard-daptation-to-Linux-4.10.0-rcX-signatures.patch
0002-UMP-Adapt-get_user_pages-calls.patch
0003-Renamed-Kernel-DMA-Fence-structures-and-functions.patch
0004-Few-modifications-after-v4.11-headers-and-signatures.patch
0005-Using-the-new-header-on-4.12-kernels-for-copy_-_user.patch
"

# -- Helper functions

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

function copy_and_apply_patches {
	patch_base_dir=$1
	patches=${@:2}
	
	apply_dir=$PWD
	cd $patch_base_dir
	cp $patches $apply_dir || 
	{ echo "Could not copy $patch"; exit 1; }
	cd $apply_dir
	git apply $patches
	rm $patches
}

# Get the kernel

# If we haven't already clone the Linux Kernel tree, clone it and move
# into the linux folder created during the cloning.
if [ ! -d "linux" ]; then
  git clone --depth 1 --branch $KERNEL_BRANCH 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git'
fi
cd linux
export SRC_DIR=$PWD

# Check if the tree is patched
if [ ! -e ".is_patched" ]; then
  # If not, cleanup, apply the patches, commit and mark the tree as 
  # patched
  
  # Remove all untracked files. These are residues from failed runs
  git clean -fdx &&
  # Rewind modified files to their initial state.
  git checkout -- .

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
  if [ ! -d "../patches" ]; then
    download_and_apply_patches $KERNEL_PATCHES_FOLDER_URL $KERNEL_PATCHES
    download_and_apply_patches $MALI_PATCHES_FOLDER $MALI_PATCHES
  else
    copy_and_apply_patches ../patches/kernel/$KERNEL_SERIES $KERNEL_PATCHES
    copy_and_apply_patches ../patches/Mali/$MALI_VERSION $MALI_PATCHES
  fi


  # Cleanup, get the configuration file and mark the tree as patched
  git add . &&
  git commit -m "Apply ALL THE PATCHES !" &&
  touch .is_patched
fi

# Download a .config file if none present
if [ ! -e ".config" ]; then
  make mrproper &&
  wget -O .config "$BASE_FILES_URL/$GITHUB_REPO/$GIT_BRANCH/boot/config-$KERNEL_VERSION$MYY_VERSION"
fi

make $MAKE_CONFIG
make $DTB_FILES zImage modules -j5

if [ $? = 0 ] && [ -z ${DONT_INSTALL_IN_TMP+x} ]; then
	# Kernel compiled
	# This will just copy the kernel files and libraries in /tmp
	# This part is only useful if you're cross-compiling the kernel, of course
	export INSTALL_MOD_PATH=/tmp/MyyQi
	export INSTALL_PATH=/tmp/MyyQi/boot
	export INSTALL_HDR_PATH=/tmp/usr
	mkdir -p $INSTALL_MOD_PATH $INSTALL_PATH $INSTALL_HDR_PATH
	make modules_install &&
	make install &&
	make INSTALL_HDR_PATH=$INSTALL_HDR_PATH headers_install && # This command IGNORES predefined variables
	cp arch/arm/boot/zImage $INSTALL_PATH &&
	cp arch/arm/boot/dts/*.dtb $INSTALL_PATH
fi


