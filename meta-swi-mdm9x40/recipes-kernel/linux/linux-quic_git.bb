inherit kernel localgit

DESCRIPTION = "QuIC Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"
COMPATIBLE_MACHINE = "(swi-mdm9x40)"

# Provide a config baseline for things so the kernel will build...
KERNEL_DEFCONFIG ?= "mdm9640_defconfig"

SRC_DIR = "${LINUX_REPO_DIR}/.."

LINUX_VERSION ?= "3.10.49"
PV = "${LINUX_VERSION}+git${GITSHA}"
PR = "r1"

DEPENDS += "dtbtool-native mkbootimg-native"

do_configure_prepend() {
    cp ${S}/arch/arm/configs/${KERNEL_DEFCONFIG} ${WORKDIR}/defconfig
}

do_compile_append() {
    oe_runmake dtbs
}

do_install_append() {
    oe_runmake headers_install O=${D}/usr/src/kernel
    oe_runmake -C $kerneldir CC="${KERNEL_CC}" LD="${KERNEL_LD}" clean _mrproper_scripts 
}

BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x40-${DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x40-${DATETIME}.4k"

MACHINE_KERNEL_BASE = "0x81800000"
MACHINE_KERNEL_TAGS_OFFSET = "0x88000000"

gen_master_dtb() {
    master_dtb_name=$1
    page_size=$2

    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    fi
    kernel_img=$(readlink -f $kernel_img)
    ls -al $kernel_img

    set -xe

    ver=$(sed -r 's/#define UTS_RELEASE "(.*)"/\1/' ${B}/include/generated/utsrelease.h)
    dtb_files=$(find ${B}/arch/arm/boot/dts -iname "*${BASEMACHINE_QCOM}*.dtb" | awk -F/ '{print $NF}' | awk -F[.][d] '{print $1}')

    # Create separate images with dtb appended to zImage for all targets.
    for d in ${dtb_files}; do
       targets=$(echo ${d#${BASEMACHINE_QCOM}-})
       cat $kernel_img ${B}/arch/arm/boot/dts/${d}.dtb > ${B}/arch/arm/boot/dts/dtb-zImage-${ver}-${targets}.dtb
    done

    ${STAGING_BINDIR_NATIVE}/dtbtool \
        ${B}/arch/arm/boot/dts/ \
        -s $page_size \
        -o ${DEPLOYDIR}/$master_dtb_name \
        -p ${S}/scripts/dtc/ \
        -v

    if ! [ -e "${DEPLOYDIR}/$master_dtb_name" ]; then
        echo "Unable to generate $master_dtb_name"
        exit 1
    fi
}

do_deploy_append() {
    gen_master_dtb masterDTB.2k 2048
    gen_master_dtb masterDTB.4k 4096
}

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    master_dtb_name=$4
    page_size=$5

    set -xe

    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    fi
    kernel_img=$(readlink -f $kernel_img)
    ls -al $kernel_img

    # Initramfs
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --dt ${DEPLOYDIR}/$master_dtb_name \
        --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS_RAMDISK}" \
        --pagesize $page_size \
        --base ${MACHINE_KERNEL_BASE} \
        --tags-addr ${MACHINE_KERNEL_TAGS_OFFSET} \
        --ramdisk_offset 0x0 \
        --output ${DEPLOY_DIR_IMAGE}/${image_name}.img

    ln -sf ${image_name}.img ${DEPLOY_DIR_IMAGE}/${image_link}.img
}

do_bootimg() {
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" "${BOOTIMG_NAME_2k}" boot-yocto-mdm9x40.2k masterDTB.2k 2048
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" "${BOOTIMG_NAME_4k}" boot-yocto-mdm9x40.4k masterDTB.4k 4096

    ln -sf ${BOOTIMG_NAME_2k}.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.img
}

addtask bootimg after do_deploy before do_build

