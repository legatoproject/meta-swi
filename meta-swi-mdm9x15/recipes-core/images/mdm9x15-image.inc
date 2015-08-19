DEPENDS += " \
        virtual/lk \
        yaffs2-utils-native \
        mtd-utils-native"

SRC_URI += "file://ubinize.cfg"

INC_PR = "r0"

inherit ubi-image

IMAGE_INSTALL += "shadow"
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
IMAGE_INSTALL += "libopencore-amr"
IMAGE_INSTALL += "iperf"
IMAGE_INSTALL += "iproute2-tc"
IMAGE_INSTALL += "libvo-amrwbenc"

# Required to provide some extended privileges
# to non-root processes
IMAGE_INSTALL += "libcap"
IMAGE_INSTALL += "libcap-bin"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Tools and helpers for i2c development
IMAGE_INSTALL += "i2cgpioctl"
IMAGE_INSTALL += "i2c-tools"

prepare_ubi_ps() {
    local page_size=$1

    local image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs"
    local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${page_size}.ubi"
    local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${page_size}.ubi"

    create_ubi_image $page_size ${WORKDIR}/ubinize.cfg $image_path $ubi_path $ubi_link_path
}

# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'

    # Default image (no bs suffix) to 4k
    ubi_link_path_def="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.ubi"
    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
}

default_rootfs_ps() {
    # Default yaffs2 image to 4k
    ln -sf ${IMAGE_NAME}.rootfs.4k.yaffs2 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.yaffs2

    # Default rootfs to ubi for 2k
    ln -sf ${IMAGE_LINK_NAME}.2k.ubi    ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.2k.default

    # Default rootfs to yaffs2 for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.yaffs2 ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.default
}

do_rootfs[postfuncs] += "prepare_ubi"
do_rootfs[postfuncs] += "default_rootfs_ps"

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

