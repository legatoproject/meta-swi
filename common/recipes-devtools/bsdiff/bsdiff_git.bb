SUMMARY = "Binary delta tools and library"
DESCRIPTION = "This is Debian version of bsdiff and bspatch originally written by \
               Colin Percival. The only difference is that Debian applied important \
	       patches to make tools more secure and hardened."
HOMEPAGE = "http://www.daemonology.net/bsdiff/"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://debian/copyright;md5=64e8a8b4894377726b48c8a346210d25"
SRC_REPO = "git://salsa.debian.org/debian/bsdiff.git;protocol=https"
SRCREV = "b01df825a4998c00bcf1bb0d622e297ec66cd17c"

# Useful, if we do not have make targets like "clean", etc.
inherit autotools

# We do not need to create separate nativesdk-* and *-native recipes
# if we make this declaration.
BBCLASSEXTEND = "native nativesdk"

# Package version
VERSNUM = "4.3-21"

# Recipe version
RR = "1"

PV = "${VERSNUM}"
PR = "r${RR}"

# Source and build directories.
S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

# Sources
SRC_URI = "${SRC_REPO}"
SRC_URI += "file://0001-makefile-fix.patch"

# Where to find additional files
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# This package depends on bzip2 even at runtime.
DEPENDS_BZIP2 = "bzip2-replacement-native"
DEPENDS_BZIP2_class-target = "bzip2"
DEPENDS_BZIP2_class-nativesdk = "nativesdk-bzip2"
DEPENDS = "${DEPENDS_BZIP2}"
RDEPENDS_${PN} += "bzip2"

# Avoid installed-vs-shipped errors.
FILES_${PN} += "${bindir}/bsdiff ${bindir}/bspatch"

# EXTRA_CFLAGS and EXTRA_LDFLAGS are expected by package Makefile,
# BUILD_CFLAGS and BUILD_LDFLAGS are Yocto exported build variables.
EXTRA_CFLAGS += "${BUILD_CFLAGS}"
EXTRA_LDFLAGS += "${BUILD_LDFLAGS}"

# We need to apply patches located in the package itself, and SRC_URI
# does not work in that case (patches may not be available at the time
# of do_fetch).
# Patching must be done before compilation starts, hence add new task
# to fulfill our needs.
# Note that we need "build" directory, and this one is created by
# do_configure step.
do_patch_extra() {

    local deb_patches=""

    cd ${S}/debian/patches
    deb_patches=$( ls *.patch | sort )

    # Need sources in build directory, because Yocto
    # wants to build there.
    cp -arf ${S}/* ${B}/.

    # We need patches located in Debian sources.
    cd ${B}
    for patch_file in ${deb_patches} ; do
        patch -p1 <${S}/debian/patches/${patch_file}
    done
}
addtask patch_extra after do_configure before do_compile

do_install() {
    install -m 0755 ${B}/bsdiff -D ${D}/${bindir}/bsdiff
    install -m 0755 ${B}/bspatch -D ${D}/${bindir}/bspatch
}
