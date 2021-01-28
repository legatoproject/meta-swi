###############################################################################
# Author: Dragan Marinkovic (dmarinkovi@sierrawireless.com)
# Copyright (c) 2021, Sierra Wireless Inc. All rights reserved.
###############################################################################
#
# Tinyalsa is scaled down version of alsa utilities. These utils are required
# by kernel 4.14 audio subsystem.
#
# #############################################################################

LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://NOTICE;md5=e04cd6fa58488e016f7fb648ebea1db4"
DESCRIPTION = "Simplified Linux ALSA Utils"

SRCREV = "35ceabda237121077eae2515b52b25cd3d866eef"
SRC_REPO = "git://android.googlesource.com/platform/external/tinyalsa;protocol=https;branch=master"
SRC_URI[md5sum] = "27fac0657e9eb8bc99206ed523a23839"
SRC_URI[sha256sum] = "b1d448828b6f8df45bc5b0eda2e849d11e5c01df8c551f41687555764b168099"
PR = "r0"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-files:"
SRC_URI = "${SRC_REPO}"
S = "${WORKDIR}/git"
B = "${S}"

# Additional files
SRC_URI_FILES += " \
                 "
# Patches
SRC_URI_PATCHES += " \
                    file://0001-tinyalsa.patch \
                   "

# Add it all together
SRC_URI += "${SRC_URI_FILES} ${SRC_URI_PATCHES}"

CPPFLAGS += "-Iinclude -Wno-unused-result"

do_compile () {
    # tinycap (recording)
    ${CC} ${CPPFLAGS} ${LDFLAGS} -O tinycap.c pcm.c -o tinycap

    # tinyplay (player)
    ${CC} ${CPPFLAGS} ${LDFLAGS} -O tinyplay.c pcm.c -o tinyplay

    # tinymix (mixer)
    ${CC} ${CPPFLAGS} ${LDFLAGS} -O tinymix.c mixer.c -o tinymix

    # tinyhostless
    ${CC} ${CPPFLAGS} ${LDFLAGS} -O tinyhostless.c pcm.c -o tinyhostless
}

do_install () {
    mkdir -p ${D}${bindir}
    install -m 0755 ${B}/tinycap ${D}${bindir}/tinycap
    install -m 0755 ${B}/tinyplay ${D}${bindir}/tinyplay
    install -m 0755 ${B}/tinymix ${D}${bindir}/tinymix
    install -m 0755 ${B}/tinyhostless ${D}${bindir}/tinyhostless
}
