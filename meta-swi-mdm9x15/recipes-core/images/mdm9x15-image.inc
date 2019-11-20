DEPENDS += " \
        virtual/lk \
        mtd-utils-native"

SRC_URI += "file://ubinize.cfg"
SRC_URI += "file://ubinize-user1.cfg"

INC_PR = "r0"

inherit ubi-image

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL_append = " busybox-mdev"

# Add WiFi TI drivers, tools, and scripts
IMAGE_INSTALL_append = " wpa-supplicant"
IMAGE_INSTALL_append = " hostapd"
IMAGE_INSTALL_append = " iw"
IMAGE_INSTALL_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', ' ti-wifi-utils-wl18xx', '', d)}"
IMAGE_INSTALL_append = " crda"
IMAGE_INSTALL_append = " i2cgpioctl"
IMAGE_INSTALL_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', ' sierra-init-tiwifi', '', d)}"

# Install kernel modules
IMAGE_INSTALL_append = " kernel-modules"

# Install device trees to rootfs (/boot directory is default location).
IMAGE_INSTALL_append = " kernel-devicetree"

# Add linkmon app to monitor USB link
IMAGE_INSTALL_append = " linkmon"

# Add timezone related packages
IMAGE_INSTALL_append = " tzdata"
IMAGE_INSTALL_append = " tzone-utils"

# Create UBI images for ROOT and USER1 partitions. If it becomes longer, this
# function should be optimized (creation of sub-methods, etc.)
prepare_ubi_ps() {
    local page_size=$1

    # Initially, set for root partition
    local ubi_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.${page_size}.ubi"
    local ubi_link_path="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${page_size}.ubi"
    local ubinize_cfg=${WORKDIR}/gen_ubinize.cfg

    # Process root partition UBI
    cp -af ${WORKDIR}/ubinize.cfg $ubinize_cfg
    sed -i -e "s|@@ROOTFS_PATH@@|${UBI_ROOTFS_PATH}|g" $ubinize_cfg
    sed -i -e "s|@@ROOTFS_SIZE@@|${UBI_ROOTFS_SIZE}|g" $ubinize_cfg
    create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path

    # Process USER1 UBI
    ubi_path="${IMGDEPLOYDIR}/${IMAGE_NAME}-user1.${page_size}.ubi"
    ubi_link_path="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}-user1.${page_size}.ubi"
    ubinize_cfg=${WORKDIR}/gen_ubinize.cfg

    cp -af ${WORKDIR}/ubinize-user1.cfg $ubinize_cfg
    sed -i -e "s|@@USER1_PATH@@|${UBI_USER1_PATH}|g" $ubinize_cfg
    sed -i -e "s|@@USER1_SIZE@@|${UBI_USER1_SIZE}|g" $ubinize_cfg
    create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
}

# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'

    cd ${IMGDEPLOYDIR}

    # Default image (no bs suffix) to 4k
    ubi_link_path_def="${IMAGE_LINK_NAME}.4k.ubi"
    ubi_link_path="${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
}

default_rootfs_ps() {
    cd ${IMGDEPLOYDIR}

    # Default rootfs to ubi for 2k and 4k
    ln -sf ${IMAGE_LINK_NAME}.2k.ubi    ${IMAGE_LINK_NAME}.2k.default
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi    ${IMAGE_LINK_NAME}.4k.default
}

do_image_complete[postfuncs] += "prepare_ubi"
do_image_complete[postfuncs] += "default_rootfs_ps"

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

require mdm9x15-image-cwe.inc
