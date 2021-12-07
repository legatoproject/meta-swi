SUMMARY = "Binary delta tools and library"
DESCRIPTION = "This is Debian version of bsdiff and bspatch originally written by \
               Colin Percival. The only difference is that Debian applied important \
	       patches to make tools more secure and hardened."
HOMEPAGE = "http://www.daemonology.net/bsdiff/"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://debian/copyright;md5=c372de180ddb86b67ed1494b0fcf459c"
SRC_REPO = "git://salsa.debian.org/debian/bsdiff.git;protocol=https"
SRCREV = "b800a816106270f2c4e7619bf384005c8f85daec"

# We do not need to create separate nativesdk-* and *-native recipes
# if we make this declaration.
BBCLASSEXTEND = "native nativesdk"

# Package version
VERSNUM = "4.3-22"

# Recipe version
RR = "1"

PV = "${VERSNUM}"
PR = "r${RR}"

# Source directory
S = "${WORKDIR}/git"
# Build directory same as source: bsdiff doesn't support separate build dir.
B = "${S}"

# Sources
SRC_URI = "${SRC_REPO}"
SRC_URI += "file://0001-makefile-fix.patch"
SRC_URI += "file://0002-package-as-library.patch"

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

# Pure Makefile project; no configure script
do_configure[noexec] = "1"

do_install() {
    install -m 0755 ${B}/bsdiff -D ${D}/${bindir}/bsdiff
    install -m 0755 ${B}/bspatch -D ${D}/${bindir}/bspatch
    install -m 0755 ${B}/libbsdiff.so -D ${D}/${libdir}/libbsdiff.so.0.1
    install -m 0755 ${B}/libbspatch.so -D ${D}/${libdir}/libbspatch.so.0.1
    install -m 0644 ${S}/bsdiff.h -D ${D}/${includedir}/bsdiff.h
}
