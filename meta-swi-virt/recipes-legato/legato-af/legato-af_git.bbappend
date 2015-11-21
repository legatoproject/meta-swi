LEGATO_ROOTFS_TARGETS = "virt"

libdir = "/mnt/legato/usr/local/lib"

do_compile_prepend() {
    export VIRT_TARGET_ARCH=${VIRT_ARCH}
}

do_install_append() {
    mkdir -p ${D}/mnt/legato

    first_target=$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')
    cp -R ${S}/build/$first_target/staging/* ${D}/mnt/legato

    mkdir -p ${D}/mnt/flash
}

FILES_${PN}-dbg += "mnt/legato/usr/local/*/.debug/*"
FILES_${PN}-dbg += "mnt/legato/system/*/.debug/*"
FILES_${PN}-dbg += "mnt/legato/apps/*/read-only/*/.debug/*"
FILES_${PN}  = "mnt/legato/*"
FILES_${PN} += "mnt/flash"
FILES_${PN} += "opt/*"
