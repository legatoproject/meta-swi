DESCRIPTION = "Tool to control IO expender through I2C on MangOH"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://../COPYING;md5=751419260aa954499f7abaabaa882bbe"
PR = "r0"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI  = "file://COPYING"
SRC_URI += "file://i2cgpioctl.c"
SRC_URI += "file://gpioexp.c"

# Tools sources are extracted from i2c-tools-3.1.0
SRC_URI += "file://tools/i2c-dev.h"
SRC_URI += "file://tools/i2cbusses.c"
SRC_URI += "file://tools/i2cbusses.h"
SRC_URI += "file://tools/util.c"
SRC_URI += "file://tools/util.h"

TARGET_CFLAGS_swi-mdm9x15_append = " -DCONFIG_MDM9X15"
TARGET_CFLAGS_swi-mdm9x28_append = " -DCONFIG_MDM9X28"
# DM, FIXME: We could do '-DCONFIG_MDM9X28 -DCONFIG_MDM9X28_FX30' if it turns out
# that all changes made for mdm9x28 apply to fx30 as well.
TARGET_CFLAGS_swi-mdm9x28-fx30_append = " -DCONFIG_MDM9X28_FX30"

S="${WORKDIR}/sources"

generate_version() {
    echo "#define VERSION \"${PV}\"" > ${S}/version.h
}

copy_sources() {
    mv ${WORKDIR}/i2cgpioctl.c  ${S}
    # Include gpioexp for MDM9X15, MDM9X28 and MDM9X28_FX30
    if ${@bb.utils.contains_any('MACHINE','swi-mdm9x28 swi-mdm9x15 swi-mdm9x28-fx30','true','false',d)}; then
        mv ${WORKDIR}/gpioexp.c  ${S}
    fi
    mv ${WORKDIR}/tools         ${S}
}

do_unpack[postfuncs] += "copy_sources"
do_unpack[postfuncs] += "generate_version"

do_compile() {
    cd ${S}
    ${CC} ${CFLAGS} ${LDFLAGS} -g -o i2cgpioctl -I tools i2cgpioctl.c tools/util.c tools/i2cbusses.c
    # Include gpioexp for MDM9X15, MDM9X28 and MDM9X28_FX30
    if ${@bb.utils.contains_any('MACHINE','swi-mdm9x28 swi-mdm9x15 swi-mdm9x28-fx30','true','false',d)}; then
        ${CC} ${CFLAGS} ${LDFLAGS} -g -o gpioexp -I tools gpioexp.c
    fi
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/i2cgpioctl ${D}${bindir}
    # Include gpioexp for MDM9X15, MDM9X28 and MDM9X28_FX30
    if ${@bb.utils.contains_any('MACHINE','swi-mdm9x28 swi-mdm9x15 swi-mdm9x28-fx30','true','false',d)}; then
        install -m 0755 ${S}/gpioexp ${D}${bindir}
    fi
}
