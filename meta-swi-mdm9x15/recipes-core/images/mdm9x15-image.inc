DEPENDS += " \
        virtual/lk \
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

# Create UBI image
prepare_ubi() {
    local cimg=${DEPLOY_DIR_IMAGE}/ubinize.cfg

    local image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs"
    local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.ubi"
    local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"

    if ! [ -e "$image_path" ]; then
        echo "${IMAGE_NAME} doesn't exist"
        exit 1
    fi

    echo "Using image: '$image_path'"

    cp -af ${WORKDIR}/ubinize.cfg ${cimg}
    sed -i -e "s|@@IMAGE_PATH@@|$image_path|g" ${cimg}

    ${STAGING_DIR_NATIVE}/usr/sbin/ubinize -o $ubi_path -m 4096 -p 256KiB -s 4096 ${DEPLOY_DIR_IMAGE}/ubinize.cfg

    rm -f $ubi_link_path
    ln -s $(basename $ubi_path) $ubi_link_path
}

do_rootfs[postfuncs] += "prepare_ubi"

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

