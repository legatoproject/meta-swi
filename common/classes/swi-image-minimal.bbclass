DESCRIPTION = "A small image just capable of allowing SWI products to boot."

CORE_SWI_IMAGE ?= "packagegroup-swi-image-target"
EXTENDED_SWI_IMAGE ?= "packagegroup-swi-image-target-ext"

ROOTFS_PKGMANAGE_BOOTSTRAP ??= ""
IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL} ${CORE_SWI_IMAGE}"

# Enable debug packages
IMAGE_INSTALL_append = " ${@bb.utils.contains('EXT_SWI_IMG', 'true', '${EXTENDED_SWI_IMAGE}', '', d)}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image
inherit swi-version

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_TYPE ?= "minimal"

PR = "${INC_PR}.0"

# Only add Legato if this is a LEGATO_BUILD
def check_legato_pkg(d, package="legato-af"):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return package
    return ""

# Make sure that some content is not in the rootfs
do_rm_unused_files() {
    rm -f "${IMAGE_ROOTFS}/etc/shadow-"
    rm -f "${IMAGE_ROOTFS}/etc/gshadow-"
}

fakeroot do_label_files() {
    # Set SMACK labels on selected files
    if [ -f "${IMAGE_ROOTFS}/etc/init.d/dropbear" ] ; then
        setfattr -n security.SMACK64EXEC -v admin \
            "${IMAGE_ROOTFS}/etc/init.d/dropbear"
    fi
    if [ -f "${IMAGE_ROOTFS}/usr/bin/qmuxd" ] ; then
        setfattr -n security.SMACK64EXEC -v qmuxd \
            "${IMAGE_ROOTFS}/usr/bin/qmuxd"
    fi
    if [ -f "${IMAGE_ROOTFS}/usr/sbin/tzoneset" ] ; then
        setfattr -n security.SMACK64EXEC -v _ \
            "${IMAGE_ROOTFS}/usr/sbin/tzoneset"
    fi
    if [ -f "${IMAGE_ROOTFS}/etc/init.d/run_getty.sh" ] ; then
        setfattr -n security.SMACK64EXEC -v admin \
            "${IMAGE_ROOTFS}/etc/init.d/run_getty.sh"
    fi
}

IMAGE_PREPROCESS_COMMAND_append = " do_rm_unused_files; do_label_files; "
