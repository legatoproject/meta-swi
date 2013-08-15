inherit native

MY_PN = "mkbootimg"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "mkbootimg-native"

DEPENDS = "libmincrypt-native"

PR = "r0"

SRC_URI = "file://mkbootimg.tar.bz2"

EXTRA_OEMAKE = "INCLUDES='-Imincrypt' LIBS='${libdir}/mincrypt/libmincrypt.a'"

do_install() {
	install -d ${D}${bindir}
	install ${MY_PN} ${D}${bindir}
}

NATIVE_INSTALL_WORKS = "1"
