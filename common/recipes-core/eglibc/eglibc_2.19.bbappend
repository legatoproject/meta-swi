# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

do_install_append() {

    # Tell the world location of libc binary. Kernel build will look for this file.
    echo "${D}/../package" >${TOPDIR}/tmp/libc.loc

    # Tell the world location of ld binary. Kernel build will look for this file.
    echo "${D}/../package" >${TOPDIR}/tmp/ld.loc
}
