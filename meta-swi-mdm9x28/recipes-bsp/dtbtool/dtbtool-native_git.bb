inherit native

PR = "r0"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "dtbtool-native"

# Tag LE.UM.1.1-23600-9x07
SRCREV = "870cf8f91bc89785ea47c79ae152eb1d858d6e01"
DTBTOOL_NATIVE_REPO = "git://codeaurora.org/device/qcom/common;branch=jb_rb5.1"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "${DTBTOOL_NATIVE_REPO}"
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
