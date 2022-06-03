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
DEBIAN_SNAPSHOT_VERSION = "20220607T090313Z"

SRC_URI = "\
https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT_VERSION}/pool/main/f/fakeroot/fakeroot_${PV}.orig.tar.gz \
"

# Sierra Wireless home grown ...
SRC_URI += "file://0001-cability-Fix-libfakeroot.c-related-compilation-error.patch \
            file://0003-libfakeroot.c-Force-linking-older-versions-of-dlerro.patch \
           "

inherit autotools

CFLAGS:append = " -DHAVE_LINUX_CAPABILITY_H"

do_configure:prepend() {
    mkdir -p "${S}/build-aux"
}

do_configure:prepend:class-nativesdk() {
    pushd "${STAGING_DIR_TARGET}${SDKPATHNATIVE}/lib/"
    ln -sf libdl.so.2 libdl.so
    popd
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
SRC_URI[md5sum] = "cab9604a7dc1d58346e0d15bb285bd0f"
SRC_URI[sha256sum] = "8fbbafb780c9173e3ace4a04afbc1d900f337f3216883939f5c7db3431be7c20"

# http://errors.yoctoproject.org/Errors/Details/35143/
SKIP_RECIPE[fakeroot] ?= "BROKEN: QA Issue: -dev package contains non-symlink .so"

BBCLASSEXTEND = "native nativesdk"
