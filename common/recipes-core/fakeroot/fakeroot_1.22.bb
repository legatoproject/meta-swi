SUMMARY = "Gives a fake root environment"
HOMEPAGE = "http://fakeroot.alioth.debian.org"
SECTION = "base"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://COPYING;md5=f27defe1e96c2e1ecd4e0c9be8967949"

S = "${WORKDIR}/fakeroot-${PV}"

# Fix "QA Issue: -dev package contains non-symlink .so"
FILES_SOLIBSDEV = ""
FILES_${PN} += "${libdir}/*.so"

# Archives can be deleted from the latest mirror, so pick a snapshot
# corresponding to this fakeroot version.
DEBIAN_SNAPSHOT_VERSION = "20170817T093655Z"

SRC_URI = "\
    https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT_VERSION}/pool/main/f/fakeroot/fakeroot_${PV}.orig.tar.bz2 \
"

# From http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.22-2.debian.tar.xz
SRC_URI += "file://eglibc-fts-without-LFS.patch \
            file://fix-shell-in-fakeroot.patch \
            file://hide-dlsym-error.patch \
            file://glibc-xattr-types.patch \
           "

# Sierra Wireless home grown ...
SRC_URI += "file://0001-cability-Fix-libfakeroot.c-related-compilation-error.patch"

inherit autotools

# Compatability for the rare systems not using or having SYSV
# Use tcp instead of unix sockets to work on Windows.
EXTRA_OECONF = " --with-ipc=tcp --program-prefix="

EXTRA_OEMAKE = "'CFLAGS=-I${STAGING_INCDIR} -DHAVE_LINUX_CAPABILITY_H'"

do_configure_prepend() {
    mkdir -p "${S}/build-aux"
}

do_install_append() {
    install -d ${D}${includedir}/fakeroot
    install -m 644 *.h ${D}${includedir}/fakeroot
}

# fakeroot needs getopt which is provided by the util-linux package,
# it also needs libcap.
DEPENDS = "libcap"
RDEPENDS_${PN} = "util-linux libcap"

SRC_URI[md5sum] = "fae64c9aeb2c895ead8e1b99bf50c631"
SRC_URI[sha256sum] = "bd806a4a1e641203eb3d4571a10089e8a038c10ec7e492fa1e061b03ae3ec6fe"

# http://errors.yoctoproject.org/Errors/Details/35143/
PNBLACKLIST[fakeroot] ?= "BROKEN: QA Issue: -dev package contains non-symlink .so"

BBCLASSEXTEND = "native nativesdk"
