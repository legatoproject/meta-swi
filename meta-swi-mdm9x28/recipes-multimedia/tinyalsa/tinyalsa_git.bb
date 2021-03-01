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
                  file://tinyalsa_lib.h \
                 "
# Patches
SRC_URI_PATCHES += " \
                    file://0001-tinyalsa.patch \
                    file://0002-tinyalsa-Make-tinyalsa-libraries.patch \
                    file://0003-tinyalsa-Build-tinyhostless-as-a-library.patch \
                   "

# Add it all together
SRC_URI += "${SRC_URI_FILES} ${SRC_URI_PATCHES}"

CPPFLAGS += "-O -Iinclude -Wno-unused-result"

# Include this if shared libraries are required.
CPPFLAGS_TINYALSA_AS_LIB = " -DTINYALSA_AS_LIB -shared -fPIC -Wl,--no-undefined -lc"

do_compile () {

    #
    # Build executables
    #

    # tinycap (recording)
    ${CC} ${CPPFLAGS} ${LDFLAGS} tinycap.c pcm.c -o tinycap

    # tinyplay (player)
    ${CC} ${CPPFLAGS} ${LDFLAGS} tinyplay.c pcm.c -o tinyplay

    # tinymix (mixer)
    ${CC} ${CPPFLAGS} ${LDFLAGS} tinymix.c mixer.c -o tinymix

    # tinyhostless
    ${CC} ${CPPFLAGS} ${LDFLAGS} tinyhostless.c pcm.c -o tinyhostless

    #
    # Build shared libraries
    #
    #tinycap
    ${CC} ${CPPFLAGS} ${LDFLAGS} ${CPPFLAGS_TINYALSA_AS_LIB} -Wl,-soname,libtinycap.so.1 -o libtinycap.so.1.0.0 tinycap.c pcm.c

    # tinyplay
    ${CC} ${CPPFLAGS} ${LDFLAGS} ${CPPFLAGS_TINYALSA_AS_LIB} -Wl,-soname,libtinycap.so.1 -o libtinyplay.so.1.0.0 tinyplay.c pcm.c

    # tinymix
    ${CC} ${CPPFLAGS} ${LDFLAGS} ${CPPFLAGS_TINYALSA_AS_LIB} -Wl,-soname,libtinycap.so.1 -o libtinymix.so.1.0.0 tinymix.c mixer.c

    # tinyhostless
    ${CC} ${CPPFLAGS} ${LDFLAGS} ${CPPFLAGS_TINYALSA_AS_LIB} -Wl,-soname,libtinyhostless.so.1 -o libtinyhostless.so.1.0.0 tinyhostless.c pcm.c

}

do_install () {
    mkdir -p ${D}${bindir}
    install -m 0755 ${B}/tinycap ${D}${bindir}/tinycap
    install -m 0755 ${B}/tinyplay ${D}${bindir}/tinyplay
    install -m 0755 ${B}/tinymix ${D}${bindir}/tinymix
    install -m 0755 ${B}/tinyhostless ${D}${bindir}/tinyhostless

    mkdir -p ${D}${libdir}
    install -m 0644 ${B}/libtinycap.so.1.0.0 ${D}${libdir}/libtinycap.so.1.0.0
    install -m 0644 ${B}/libtinyplay.so.1.0.0 ${D}${libdir}/libtinyplay.so.1.0.0
    install -m 0644 ${B}/libtinymix.so.1.0.0 ${D}${libdir}/libtinymix.so.1.0.0
    install -m 0644 ${B}/libtinyhostless.so.1.0.0 ${D}${libdir}/libtinyhostless.so.1.0.0

    cd ${D}${libdir}
    ln -s libtinycap.so.1.0.0 libtinycap.so.1
    ln -s libtinycap.so.1.0.0 libtinycap.so

    ln -s libtinyplay.so.1.0.0 libtinyplay.so.1
    ln -s libtinyplay.so.1.0.0 libtinyplay.so

    ln -s libtinymix.so.1.0.0 libtinymix.so.1
    ln -s libtinymix.so.1.0.0 libtinymix.so

    ln -s libtinyhostless.so.1.0.0 libtinyhostless.so.1
    ln -s libtinyhostless.so.1.0.0 libtinyhostless.so

    mkdir -p ${D}${includedir}/tinyalsa
    install -m 0644 ${WORKDIR}/tinyalsa_lib.h ${D}${includedir}/tinyalsa/tinyalsa_lib.h

}

FILES_${PN}-dev = "${libdir}/lib*.so ${includedir}/tinyalsa/tinyalsa_lib.h"
FILES_${PN} = "${bindir}/* ${libdir}/lib*.so.*"
