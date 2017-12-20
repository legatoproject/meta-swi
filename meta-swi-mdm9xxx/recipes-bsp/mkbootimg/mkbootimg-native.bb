inherit native

MY_PN = "mkbootimg"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "mkbootimg-native"

DEPENDS = "libmincrypt-native"

PR = "r1"

# Tag LNX.LE.2.0.2-61193-9x15
SRCREV ?= "aef3f6f231d385d616c09a39e18126fd57256ae9"
SYSTEMCORE_REPO ?= "git://codeaurora.org/platform/system/core;branch=penguin"

SRC_URI  = "${SYSTEMCORE_REPO}"
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
