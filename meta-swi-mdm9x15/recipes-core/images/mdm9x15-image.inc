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

# Create UBI image
prepare_ubi() {
    local cimg=${DEPLOY_DIR_IMAGE}/ubinize.cfg

    # Make sure ubinize.cfg variables are fully resolved.

    cp -af ${WORKDIR}/ubinize.cfg ${cimg}
    sed -i -e "s|@@DEPLOY_DIR_IMAGE@@|${DEPLOY_DIR_IMAGE}|g" ${cimg}
    sed -i -e "s|@@IMAGE_NAME@@|${IMAGE_NAME}|g" ${cimg}

    ${STAGING_DIR_NATIVE}/usr/sbin/ubinize -o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.ubi -m 4096 -p 256KiB -s 4096 ${DEPLOY_DIR_IMAGE}/ubinize.cfg
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
