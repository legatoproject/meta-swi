SUMMARY = "device-mapper-native"
DESCRIPTION = "LVM2 need this lib libdevmapper."
HOMEPAGE = "https://www.sourceware.org/dm/"
SECTION = "console"
LICENSE = "GPL-2.0-with-OpenSSL-exception"
LIC_FILES_CHKSUM = "file://COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"

SRC_URI = "ftp://sources.redhat.com/pub/dm/device-mapper.${PV}.tgz;name=tarball"
SRC_URI[tarball.md5sum] = "c9ae0776994a419f9e1ba842164bb626"
SRC_URI[tarball.sha256sum] = "24c7887fe896325a6cdc86b8beeb0d9c2de8b1c4cb20f53c2dc8f90963fc39bf"

inherit autotools gettext pkgconfig
inherit native
DEPENDS = "popt-native libxml2-native lcms-native m4-native util-linux-native libgcrypt-native openssl-native"

S = "${WORKDIR}/device-mapper.${PV}"
B = "${S}"
O = "${S}"

do_install() {
    install -d ${D}${sbindir}
    install -d ${D}${libdir}
    install -d ${D}${includedir}
    install -d ${D}${mandir}/man8
    install -d ${D}${libdir}
    install -m 0755 ${S}/dmsetup/dmsetup ${D}${sbindir}
    install -m 0755 ${S}/lib/libdevmapper.so.1.02 ${D}${libdir}
    install -m 0755 ${S}/lib/ioctl/libdevmapper.so ${D}${libdir}
    install -m 0755 ${S}/lib/ioctl/libdevmapper.a ${D}${libdir}
    install -m 0755 ${S}/include/libdevmapper.h ${D}${includedir}
    install -m 0755 ${S}/man/dmsetup.8 ${D}${mandir}/man8
}
