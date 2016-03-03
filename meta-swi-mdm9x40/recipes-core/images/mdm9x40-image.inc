DEPENDS += " \
        virtual/lk \
        mtd-utils-native"

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
IMAGE_INSTALL += "start-scripts-find-partitions"
IMAGE_INSTALL += "start-scripts-firmware-links"
IMAGE_INSTALL += "conntrack-tools"

# Required to provide some extended privileges
# to non-root processes
IMAGE_INSTALL += "libcap"
IMAGE_INSTALL += "libcap-bin"

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
IMAGE_INSTALL += "bsinfo"

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

    echo \[usrfs_volume\] >> $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="${UBI_USRFS_PATH}" >> $cfg_path
    echo vol_id=1 >> $cfg_path
    echo vol_type=dynamic >> $cfg_path
    echo vol_name=usrfs >> $cfg_path
    echo vol_flags=autoresize >> $cfg_path
    echo >> $cfg_path

    echo \[cache_volume\] >> $cfg_path
    echo mode=ubi >> $cfg_path
    echo vol_id=2 >> $cfg_path
    echo vol_type=dynamic >> $cfg_path
    echo vol_name=cachefs >> $cfg_path
    echo vol_size=${UBI_CACHE_SIZE} >> $cfg_path
}

create_usrfs() {
    rm -rf "${WORKDIR}/usrfs"
    mkdir -p "${WORKDIR}/usrfs"

    mkfs.ubifs -r "${WORKDIR}/usrfs" -o ${UBI_USRFS_PATH} ${MKUBIFS_ARGS}
}

do_rootfs[prefuncs] += "create_usrfs"

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
    prepare_ubi_ps '2k'
    #prepare_ubi_ps '4k'

    # Default image (no bs suffix) to 2k + squashfs
    ubi_link_path_def="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs.2k.ubi"
    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.2k.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path

    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
}

do_rootfs[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    # Default rootfs to ubi for 2k
    ln -sf ${IMAGE_LINK_NAME}.2k.ubi     ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.2k.default

    # Default rootfs to yaffs2 for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.yaffs2  ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 2k
    ln -sf ${IMAGE_LINK_NAME}.2k.default ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.default
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

