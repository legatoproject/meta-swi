DEPENDS += " \
        virtual/lk \
        mtd-utils-native"

INC_PR = "r0"

inherit ubi-image

IMAGE_INSTALL += "start-scripts-find-partitions"
IMAGE_INSTALL += "start-scripts-firmware-links"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Tools and helpers for i2c development
IMAGE_INSTALL += "i2c-tools"

# Only add Legato if this is a LEGATO_BUILD
def check_legato_pkg(d):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return "legato-image"
    return ""

DEPENDS += "${@check_legato_pkg(d)}"

# AR8161
IMAGE_INSTALL += "pciutils"
IMAGE_INSTALL += "alx"
IMAGE_INSTALL += "kernel-module-alx"

# Stubs
IMAGE_INSTALL += "bsinfo-stub"

# Add some extra packages for tool integration
IMAGE_INSTALL += "lttng-ust"
#IMAGE_INSTALL += "lttng-modules"

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2

    local rootfs_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.$rootfs_type"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=0 >> $cfg_path
    echo vol_type=dynamic >> $cfg_path
    echo vol_name=rootfs >> $cfg_path
    if [[ "$rootfs_type" != "squashfs" ]]; then
        echo vol_size="${UBI_ROOTFS_SIZE}" >> $cfg_path
    fi
    echo >> $cfg_path

    echo \[cache_volume\] >> $cfg_path
    echo mode=ubi >> $cfg_path
    echo vol_id=1 >> $cfg_path
    echo vol_type=dynamic >> $cfg_path
    echo vol_name=cachefs >> $cfg_path
    echo vol_size=${UBI_CACHE_SIZE} >> $cfg_path
}

prepare_ubi_ps() {
    local page_size=$1

    local ubinize_cfg="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.ubinize.cfg"

    for rootfs_type in ubifs squashfs; do
        create_ubinize_config $ubinize_cfg $rootfs_type

        local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '4k'

    # Default image (no bs suffix) to 2k + squashfs
    ubi_link_path_def="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs.4k.ubi"
    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path

    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
}

do_rootfs[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.default
}

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

