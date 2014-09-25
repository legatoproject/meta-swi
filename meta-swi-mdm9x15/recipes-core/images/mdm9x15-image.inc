DEPENDS += " \
        virtual/lk \
        mkbootimg-native \
        yaffs2-utils-native"

INC_PR = "r0"

IMAGE_INSTALL += "dnsmasq"
IMAGE_INSTALL += "powerapp"
IMAGE_INSTALL += "powerapp-powerconfig"
IMAGE_INSTALL += "powerapp-reboot"
IMAGE_INSTALL += "powerapp-shutdown"
IMAGE_INSTALL += "bridge-utils"
IMAGE_INSTALL += "pimd"
IMAGE_INSTALL += "reboot-daemon"
IMAGE_INSTALL += "procps"
IMAGE_INSTALL += "mtd-utils"
IMAGE_INSTALL += "mtd-utils-ubifs"

# Make the bootimg image file using the information available in the sysroot...
createimg() {
    ver=`cat ${STAGING_KERNEL_DIR}/kernel-abiversion`
    kernelsize=`awk --non-decimal-data '/ _end/ {end="0x" $1} /_stext/ {beg="0x" $1} END {size1=end-beg+4096; size=and(size1,compl(4095)); printf("%#x",size)}' ${STAGING_DIR_TARGET}/usr/src/kernel/System.map-${ver}`

    ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg --kernel ${STAGING_DIR_TARGET}/usr/src/kernel/Image \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS}" \
        --base 0x40800000 \
        ${MKBOOTIMG_IMAGE_FLAGS_4K} \
        --ramdisk_offset $kernelsize \
        --output ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x15.img

    rm -f ${DEPLOY_DIR_IMAGE}/kernel
    ln -s ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x15.img ${DEPLOY_DIR_IMAGE}/kernel
}

ROOTFS_POSTPROCESS_COMMAND += "createimg;"
