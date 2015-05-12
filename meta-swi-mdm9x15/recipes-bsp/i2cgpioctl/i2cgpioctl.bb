DESCRIPTION = "Tool to control IO expender through I2C on MangOH"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://../COPYING;md5=751419260aa954499f7abaabaa882bbe"
PR = "r0"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI  = "file://COPYING"
SRC_URI += "file://i2cgpioctl.c"

# Tools sources are extracted from i2c-tools-3.1.0
SRC_URI += "file://tools/i2c-dev.h"
SRC_URI += "file://tools/i2cbusses.c"
SRC_URI += "file://tools/i2cbusses.h"
SRC_URI += "file://tools/util.c"
SRC_URI += "file://tools/util.h"

S="${WORKDIR}/sources"

generate_version() {
    echo "#define VERSION \"${PV}\"" > ${S}/version.h
}

copy_sources() {
    mv ${WORKDIR}/i2cgpioctl.c  ${S}
    mv ${WORKDIR}/tools         ${S}
}

do_unpack[postfuncs] += "copy_sources"
do_unpack[postfuncs] += "generate_version"

do_compile() {
    cd ${S}
    ${CC} -g -o i2cgpioctl -I tools i2cgpioctl.c tools/util.c tools/i2cbusses.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/i2cgpioctl ${D}${bindir}
}
