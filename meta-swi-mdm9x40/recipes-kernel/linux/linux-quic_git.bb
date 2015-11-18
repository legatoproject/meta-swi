inherit kernel localgit

DESCRIPTION = "QuIC Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"
COMPATIBLE_MACHINE = "(swi-mdm9x40)"

# Provide a config baseline for things so the kernel will build...
KERNEL_DEFCONFIG ?= "mdm9640_defconfig"

SRC_DIR = "${WORKSPACE}/../../kernel"

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
    rm -rf ${D}/usr/src/kernel/scripts
}

require linux-dtb.inc

BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x40-${DATETIME}.4k"

MACHINE_KERNEL_BASE = "0x81800000"
MACHINE_KERNEL_TAGS_OFFSET = "0x88000000"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    page_size=$4

    set -xe

    if ! [ -e "${DEPLOY_DIR_IMAGE}" ]; then
        mkdir -p ${DEPLOY_DIR_IMAGE}
    fi

    kernel_img_initramfs=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    kernel_img_initramfs=$(readlink -f $kernel_img_initramfs)
    ls -al $kernel_img_initramfs

    dtb_files=`find ${B}/arch/arm/boot/dts -iname *${BASEMACHINE_QCOM}*.dtb | awk -F/ '{print $NF}' | awk -F[.][d] '{print $1}'`

    # Create separate images with dtb appended to zImage for all targets.
    for d in ${dtb_files}; do
       targets=`echo ${d#${BASEMACHINE_QCOM}-}`
       cat $kernel_img_initramfs ${B}/arch/arm/boot/dts/${d}.dtb > ${B}/arch/arm/boot/dts/dtb-zImage-${ver}-${targets}
    done

    ${STAGING_BINDIR_NATIVE}/dtbtool \
        ${B}/arch/arm/boot/dts/ \
        -s $page_size \
        -o ${DEPLOYDIR}/masterDTB \
        -p ${S}/scripts/dtc/ \
        -v

    if ! [ -e "${DEPLOYDIR}/masterDTB" ]; then
        echo "Unable to generate masterDTB"
        exit 1
    fi

    # Initramfs
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --dt ${DEPLOYDIR}/masterDTB \
        --kernel $kernel_img_initramfs \
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
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" "${BOOTIMG_NAME_4k}" boot-yocto-mdm9x40 4096
}

addtask bootimg after do_deploy before do_build
