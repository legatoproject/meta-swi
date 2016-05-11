DEPENDS += " \
        virtual/lk \
        yaffs2-utils-native \
        mtd-utils-native"

SRC_URI += "file://ubinize.cfg"

INC_PR = "r0"

inherit ubi-image

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Tools and helpers for i2c development
IMAGE_INSTALL += "i2cgpioctl"
IMAGE_INSTALL += "i2c-tools"

# Install kernel modules
IMAGE_INSTALL += "kernel-modules"

# Install device trees to rootfs (/boot directory is default location).
IMAGE_INSTALL += "kernel-devicetree"

# Add some extra packages for tool integration
IMAGE_INSTALL += "lttng-ust"
IMAGE_INSTALL += "lttng-modules"

# Add linkmon app to monitor USB link
IMAGE_INSTALL += "linkmon"

# Add WiFi TI drivers, tools, and scripts
IMAGE_INSTALL += " ti-compat-wireless"
IMAGE_INSTALL += " sierra-init-tiwifi"
IMAGE_INSTALL += " rng-tools"

prepare_ubi_ps() {
    local page_size=$1

    local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${page_size}.ubi"
    local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${page_size}.ubi"

    local ubinize_cfg=${WORKDIR}/gen_ubinize.cfg

    cp -af ${WORKDIR}/ubinize.cfg $ubinize_cfg
    sed -i -e "s|@@ROOTFS_PATH@@|${UBI_ROOTFS_PATH}|g" $ubinize_cfg
    sed -i -e "s|@@ROOTFS_SIZE@@|${UBI_ROOTFS_SIZE}|g" $ubinize_cfg

    create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
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

