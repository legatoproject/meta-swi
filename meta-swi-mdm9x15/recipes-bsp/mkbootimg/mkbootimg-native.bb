inherit native

MY_PN = "mkbootimg"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "mkbootimg-native"

DEPENDS = "libmincrypt-native"

PR = "r1"

# Tag M9615AAAARNLZA1611263
SRCREV = "7b371cbcfc38e1485f31f8e3087a6a33211e7da2"
SRC_URI  = "git://codeaurora.org/platform/system/core;branch=penguin"
SRC_URI += "file://Makefile"

S = "${WORKDIR}/git/mkbootimg"

EXTRA_OEMAKE = "INCLUDES='-Imincrypt' LIBS='${libdir}/mincrypt/libmincrypt.a'"

copy_makefile() {
    cp ${WORKDIR}/Makefile ${S}
}

do_patch[postfuncs] += "copy_makefile"

do_install() {
	install -d ${D}${bindir}
	install ${MY_PN} ${D}${bindir}
}

NATIVE_INSTALL_WORKS = "1"
