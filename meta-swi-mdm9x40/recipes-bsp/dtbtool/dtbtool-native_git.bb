inherit native

PR = "r0"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "dtbtool-native"

# Tag LNX.LE.5.1-66221-9x40
SRCREV = "59f4c7fec32ac03e33cf94c7d6cb576649bd50fa"
SRC_URI  = "git://codeaurora.org/device/qcom/common;branch=LNX.LE.5.1_rb1.10"
SRC_URI += "file://makefile"

S = "${WORKDIR}/git/dtbtool"

copy_makefile() {
    cp ${WORKDIR}/makefile ${S}
}

do_patch[postfuncs] += "copy_makefile"

do_install() {
	install -d ${D}${bindir}
	install dtbtool ${D}${bindir}
}
