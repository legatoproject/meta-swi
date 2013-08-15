inherit native

PR = "r0"

MY_PN = "mincrypt"
MY_LPN = "libmincrypt"

DESCRIPTION = "Minimalistic encryption library from Android"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://NOTICE;md5=c19179f3430fd533888100ab6616e114"

SRC_URI = "file://libmincrypt.tar.bz2"

EXTRA_OEMAKE = "INCLUDES='-I./include'"

do_install() {
	install -d ${D}${includedir}/${MY_PN} ${D}${libdir}/${MY_PN}
	install include/${MY_PN}/*.h ${D}${includedir}/${MY_PN}
	install ${MY_LPN}.a ${D}${libdir}/${MY_PN}
}

NATIVE_INSTALL_WORKS = "1"
