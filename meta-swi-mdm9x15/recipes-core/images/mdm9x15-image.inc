DEPENDS += " \
        virtual/lk \
        mkbootimg-native \
        yaffs2-utils-native \
        mtd-utils-native"

SRC_URI += "file://ubinize.cfg"

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

# Required to provide some extended privileges
# to non-root processes
IMAGE_INSTALL += "libcap-ng"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Make the bootimg image file using the information available in the sysroot...
do_bootimg() {
    ver=`cat ${STAGING_KERNEL_DIR}/kernel-abiversion`
    kernelsize=`awk --non-decimal-data '/ _end/ {end="0x" $1} /_stext/ {beg="0x" $1} END {size1=end-beg+4096; size=and(size1,compl(4095)); printf("%#x",size)}' ${STAGING_DIR_TARGET}/usr/src/kernel/System.map-${ver}`

    ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg --kernel ${STAGING_DIR_TARGET}/usr/src/kernel/${KERNEL_IMAGETYPE} \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS}" \
        --base 0x40800000 \
        ${MKBOOTIMG_IMAGE_FLAGS_4K} \
        --ramdisk_offset $kernelsize \
        --output ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x15.img

    cd ${DEPLOY_DIR_IMAGE}
    rm -f kernel
    ln -s boot-yocto-mdm9x15.img kernel
}

addtask bootimg after do_rootfs before do_build

# Create UBI image
do_ubi() {
    local cimg=${DEPLOY_DIR_IMAGE}/ubinize.cfg

    # Make sure ubinize.cfg variables are fully resolved.

    cp -af ${WORKDIR}/ubinize.cfg ${cimg}
    sed -i -e "s|@@DEPLOY_DIR_IMAGE@@|${DEPLOY_DIR_IMAGE}|g" ${cimg}
    sed -i -e "s|@@IMAGE_NAME@@|${IMAGE_NAME}|g" ${cimg}

    ${STAGING_DIR_NATIVE}/usr/sbin/ubinize -o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.ubi -m 4096 -p 256KiB -s 4096 ${DEPLOY_DIR_IMAGE}/ubinize.cfg
}

addtask ubi after do_rootfs before do_build

# Re-enable fetch & unpack tasks, because of bug(s) in Yocto 1.6 .
do_fetch2[dirs] = "${DL_DIR}"
python do_fetch2() {
    bb.build.exec_func('base_do_fetch', d)
}

addtask fetch2

do_unpack2[dirs] = "${WORKDIR}"
python do_unpack2() {
    bb.build.exec_func('base_do_unpack', d)
}

addtask unpack2 before do_rootfs

