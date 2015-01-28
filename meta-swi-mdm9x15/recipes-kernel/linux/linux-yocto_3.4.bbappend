FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15 = "standard/swi-mdm9x15-yocto-1.6-swi"
KMETA = "meta-yocto-1.6-swi"

KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

# Use latest commits from KBRANCH & KMETA
SRCREV_machine_swi-mdm9x15 = "${AUTOREV}"
SRCREV_meta_swi-mdm9x15 = "${AUTOREV}"

# Make the bootimg image file using the information available in the sysroot...
do_bootimg[depends] += "mkbootimg-native:do_populate_sysroot"

BOOTIMG_NAME ?= "boot-yocto-mdm9x15-${DATETIME}.img"

do_bootimg() {
    kernel_size=$(awk --non-decimal-data '/ _end/ {end="0x" $1} /_stext/ {beg="0x" $1} END {size1=end-beg+4096; size=and(size1,compl(4095)); printf("%#x",size)}' System.map)
    kernel_img=arch/arm/boot/${KERNEL_IMAGETYPE}

    ls -al $kernel_img

    if ! [ -e "${DEPLOY_DIR_IMAGE}" ]; then
        mkdir -p ${DEPLOY_DIR_IMAGE}
    fi

    ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS}" \
        --base 0x40800000 \
        ${MKBOOTIMG_IMAGE_FLAGS_4K} \
        --ramdisk_offset $kernel_size \
        --output ${DEPLOY_DIR_IMAGE}/${BOOTIMG_NAME}

    cd ${DEPLOY_DIR_IMAGE}

    rm -f boot-yocto-mdm9x15.img
    ln -s ${BOOTIMG_NAME} boot-yocto-mdm9x15.img

    rm -f kernel
    ln -s boot-yocto-mdm9x15.img kernel
}

addtask bootimg after do_compile before do_build

