SUMMARY = "keyutils"
DESCRIPTION = "These tools are used to control the key management \
system built into the Linux kernel."

# PR is Yocto variable.
# This will set root build directory name to ${PV}-${PR}.
# So, if you are changing something in the base package (e.g. adding
# a patch or similar), update 'r' number.
PR = "r0"

HOMEPAGE = "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git"
SECTION = "console"

# There are two licences in this package: GPL and LGPL. We are going to use
# more restrictive one as a license for the whole package.
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://LICENCE.GPL;md5=5f6e72824f5da505c1f4a7197f004b45"

DEPENDS = ""

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils;tag=v${PV};protocol=https"

inherit autotools gettext pkgconfig

# "git" directory is used instead of directory name when version from git repo is
# downloaded from the net.
S = "${WORKDIR}/git"
B = "${S}"

do_compile() {
    oe_runmake CFLAGS="${TARGET_CFLAGS}"
}

do_install() {
    install -D ${S}/libkeyutils.so.${LIB_MAJOR} ${D}${libdir}/libkeyutils.so.${LIB_MAJOR}
    ln -sf libkeyutils.so.${LIB_MAJOR} ${D}${libdir}/libkeyutils.so.1
    ln -sf libkeyutils.so.${LIB_MAJOR} ${D}${libdir}/libkeyutils.so
    install -D ${S}/keyctl ${D}${bindir}/keyctl
    install -D ${S}/request-key ${D}${sbindir}/request-key

    # Use 'datadir' location if you want something installed in /usr/share or similar.
    # Using hard coded '/usr/share' or similar would only lead to problems in one
    # of the targets (nativesdk-*, *-native and/or platform target).
    install -D ${S}/request-key-debug.sh ${D}${datadir}/keyutils/request-key-debug.sh

    install -D ${S}/key.dns_resolver ${D}${sbindir}/key.dns_resolver
    install -D -m 0644 ${S}/request-key.conf ${D}${sysconfdir}/request-key.conf
    mkdir -p ${D}/${sysconfdir}/request-key.d
    install -D -m 0644 ${S}/keyutils.h ${D}${includedir}/keyutils.h
}

BBCLASSEXTEND = "native nativesdk"
