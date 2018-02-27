SUMMARY = "Gives a fake root environment"
HOMEPAGE = "http://fakeroot.alioth.debian.org"
SECTION = "base"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://COPYING;md5=f27defe1e96c2e1ecd4e0c9be8967949"

SRC_URI = "\
    ${DEBIAN_MIRROR}/main/f/fakeroot/fakeroot_${PV}.orig.tar.bz2 \
"

inherit autotools

EXTRA_OEMAKE = "'CFLAGS=-I${STAGING_INCDIR} -DHAVE_LINUX_CAPABILITY_H'"

do_install_append() {
    install -d ${D}${includedir}/fakeroot
    install -m 644 *.h ${D}${includedir}/fakeroot
}

# fakeroot needs getopt which is provided by the util-linux package,
# it also needs libcap.
DEPENDS = "libcap linux-libc-headers"
RDEPENDS_${PN} = "util-linux libcap"

SRC_URI[md5sum] = "fae64c9aeb2c895ead8e1b99bf50c631"
SRC_URI[sha256sum] = "bd806a4a1e641203eb3d4571a10089e8a038c10ec7e492fa1e061b03ae3ec6fe"

# http://errors.yoctoproject.org/Errors/Details/35143/
PNBLACKLIST[fakeroot] ?= "BROKEN: QA Issue: -dev package contains non-symlink .so"
