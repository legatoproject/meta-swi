inherit native

PR = "r1"

MY_PN = "mincrypt"
MY_LPN = "libmincrypt"

DESCRIPTION = "Minimalistic encryption library from Android"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://NOTICE;md5=c19179f3430fd533888100ab6616e114"

SRC_URI  = "git://codeaurora.org/platform/system/core;tag=M9615AAAARNLZA1611263;branch=penguin"
SRC_URI += "file://Makefile"

EXTRA_OEMAKE = "INCLUDES='-I${WORKDIR}/git/include'"

S = "${WORKDIR}/git/libmincrypt"

copy_makefile() {
    cp ${WORKDIR}/Makefile ${S}
}

do_patch[postfuncs] += "copy_makefile"

do_install() {
	install -d ${D}${includedir}/${MY_PN} ${D}${libdir}/${MY_PN}
	install ${WORKDIR}/git/include/${MY_PN}/*.h ${D}${includedir}/${MY_PN}
	install ${MY_LPN}.a ${D}${libdir}/${MY_PN}
}

NATIVE_INSTALL_WORKS = "1"
