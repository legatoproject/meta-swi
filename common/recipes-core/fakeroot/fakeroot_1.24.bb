SUMMARY = "Gives a fake root environment"
HOMEPAGE = "http://fakeroot.alioth.debian.org"
SECTION = "base"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://COPYING;md5=f27defe1e96c2e1ecd4e0c9be8967949"

S = "${WORKDIR}/fakeroot-${PV}"

# Fix "QA Issue: -dev package contains non-symlink .so"
FILES_SOLIBSDEV = ""
FILES:${PN} += "${libdir}/*.so"

# Archives can be deleted from the latest mirror, so pick a snapshot
# corresponding to this fakeroot version.
DEBIAN_SNAPSHOT_VERSION = "20190908T172415Z"

SRC_URI = "\
https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT_VERSION}/pool/main/f/fakeroot/fakeroot_${PV}.orig.tar.gz \
"

# Sierra Wireless home grown ...
SRC_URI += "file://0001-cability-Fix-libfakeroot.c-related-compilation-error.patch"

inherit autotools

# Compatability for the rare systems not using or having SYSV
# Use tcp instead of unix sockets to work on Windows.
EXTRA_OECONF = " --with-ipc=tcp --program-prefix="

EXTRA_OEMAKE = "'CFLAGS=-I${STAGING_INCDIR} -DHAVE_LINUX_CAPABILITY_H'"

do_configure:prepend() {
    mkdir -p "${S}/build-aux"
}

do_install:append() {
    install -d ${D}${includedir}/fakeroot
    install -m 644 *.h ${D}${includedir}/fakeroot
}

# fakeroot needs getopt which is provided by the util-linux package,
# it also needs libcap.
DEPENDS = "libcap"
RDEPENDS:${PN} = "util-linux libcap"

# for snaphot debian - orig
SRC_URI[md5sum] = "964e5f438f1951e5a515dd54edd50fa6"
SRC_URI[sha256sum] = "2e045b3160370b8ab4d44d1f8d267e5d1d555f1bb522d650e7167b09477266ed"

# http://errors.yoctoproject.org/Errors/Details/35143/
PNBLACKLIST[fakeroot] ?= "BROKEN: QA Issue: -dev package contains non-symlink .so"

BBCLASSEXTEND = "native nativesdk"
