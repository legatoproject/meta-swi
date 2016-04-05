DEPENDS += "alsa-intf"
DEPENDS += "qmi"
DEPENDS += "qmi-framework"
DEPENDS += "sierra"
DEPENDS += "loc-hal"
DEPENDS += "libopencore-amr"
DEPENDS += "yaffs2-utils-native"
DEPENDS += "libvo-amrwbenc"

libdir = "mnt/legato/system/lib"

do_install_append() {
    mkdir -p ${D}/mnt/legato

    first_target=$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')
    cp -R ${S}/build/$first_target/staging/* ${D}/mnt/legato
}

FILES_${PN}-dbg += "mnt/legato/usr/local/*/.debug/*"
FILES_${PN}-dbg += "mnt/legato/system/*/.debug/*"
FILES_${PN}-dbg += "mnt/legato/apps/*/read-only/*/.debug/*"

FILES_${PN}  = "mnt/legato/*"
FILES_${PN} += "mnt/flash"
FILES_${PN} += "opt/*"
FILES_${PN} += "mnt/legato/system/lib/*"

FILES_${PN}-dev = "usr/include/*"
