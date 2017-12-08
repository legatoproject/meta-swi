inherit native

PR = "r0"

DESCRIPTION = "Boot image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PROVIDES = "dtbtool-native"

# Tag LNX.LE.5.3-76324-9x40
SRCREV = "bbdc90ce7bbd7091190da31776f54fbe24f817c5"
SRC_URI  = "git://codeaurora.org/device/qcom/common;branch=LNX.LE.5.3"
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
