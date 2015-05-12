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
IMAGE_INSTALL += "libopencore-amr"
IMAGE_INSTALL += "iperf"
IMAGE_INSTALL += "iproute2-tc"
IMAGE_INSTALL += "i2cgpioctl"

# Required to provide some extended privileges
# to non-root processes
IMAGE_INSTALL += "libcap"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Create UBI image (for a specific page size)
prepare_ubi_ps() {
    local page_size=$1
    local cimg=${DEPLOY_DIR_IMAGE}/ubinize.cfg

    local image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs"

    local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${page_size}.ubi"
    local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${page_size}.ubi"

    if ! [ -e "$image_path" ]; then
        echo "${IMAGE_NAME} doesn't exist"
        exit 1
    fi

    echo "Using image: '$image_path'"

    cp -af ${WORKDIR}/ubinize.cfg ${cimg}
    sed -i -e "s|@@IMAGE_PATH@@|$image_path|g" ${cimg}

    local ubinize_args=''

    case $page_size in
    2k)
        ubinize_args='-m 2048 -p 128KiB -s 2048'
        ;;
    4k)
        ubinize_args='-m 4096 -p 256KiB -s 4096'
        ;;
    *)
        exit 1
        ;;
    esac

    ${STAGING_DIR_NATIVE}/usr/sbin/ubinize -o $ubi_path $ubinize_args ${DEPLOY_DIR_IMAGE}/ubinize.cfg

    rm -f $ubi_link_path
    ln -s $(basename $ubi_path) $ubi_link_path

    # Default image (no bs suffix) to 4k
    if [[ "$page_size" == "4k" ]]; then
        ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"
        rm -f $ubi_link_path
        ln -s $(basename $ubi_path) $ubi_link_path
    fi
}

# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'
}

default_rootfs_ps() {
    # Default to 4k
    ln -sf ${IMAGE_NAME}.rootfs.4k.yaffs2 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.yaffs2
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

