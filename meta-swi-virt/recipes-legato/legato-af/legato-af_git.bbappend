LEGATO_ROOTFS_TARGETS = "virt"

libdir = "/mnt/legato/usr/local/lib"

do_compile_prepend() {
    export VIRT_TARGET_ARCH=${VIRT_ARCH}
}

do_install_append() {
    mkdir -p ${D}/mnt/legato

    cp -R ${S}/build/${target}/staging/* ${D}/mnt/legato

    mkdir -p ${D}/mnt/flash
}

FILES_${PN}-dbg += "mnt/legato/usr/local/bin/.debug/*"
FILES_${PN}-dbg += "mnt/legato/usr/local/lib/.debug/*"
FILES_${PN}  = "mnt/legato/*"
FILES_${PN} += "mnt/flash"
FILES_${PN} += "opt/*"

