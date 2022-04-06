DESCRIPTION = "A small image just capable of allowing SWI products to boot."

CORE_SWI_IMAGE ?= "packagegroup-swi-image-target"
EXTENDED_SWI_IMAGE ?= "packagegroup-swi-image-target-ext"

ROOTFS_PKGMANAGE_BOOTSTRAP ??= ""
IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL} ${CORE_SWI_IMAGE}"

# Enable debug packages
IMAGE_INSTALL:append = " ${@bb.utils.contains('EXT_SWI_IMG', 'true', '${EXTENDED_SWI_IMAGE}', '', d)}"

inherit swi-image
inherit swi-version

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_TYPE ?= "minimal"

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
    if [ -f "${IMAGE_ROOTFS}/usr/sbin/run_getty.sh" ] ; then
        setfattr -n security.SMACK64EXEC -v admin \
            "${IMAGE_ROOTFS}/usr/sbin/run_getty.sh"
    fi
    if [ -f "${IMAGE_ROOTFS}/usr/sbin/restart_swi_apps" ] ; then
        setfattr -n security.SMACK64EXEC -v admin \
            "${IMAGE_ROOTFS}/usr/sbin/restart_swi_apps"
    fi
    if [ -f "${IMAGE_ROOTFS}/usr/bin/qrtr-ns" ] ; then
        setfattr -n security.SMACK64EXEC -v qmuxd \
            "${IMAGE_ROOTFS}/usr/bin/qrtr-ns"
    fi
    if [ -f "${IMAGE_ROOTFS}/usr/bin/qseecomd" ] ; then
        setfattr -n security.SMACK64EXEC -v qteelistener \
            "${IMAGE_ROOTFS}/usr/bin/qseecomd"
    fi
}

IMAGE_PREPROCESS_COMMAND:append = " do_rm_unused_files; "
IMAGE_PREPROCESS_COMMAND:append += " ${@ "do_label_files" if bb.utils.to_boolean(d.getVar('LEGATO_BUILD', True)) else "" }"
