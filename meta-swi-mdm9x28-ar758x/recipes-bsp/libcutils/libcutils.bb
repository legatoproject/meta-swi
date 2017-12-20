inherit autotools pkgconfig

DESCRIPTION = "Build Android libcutils"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "0918d945560b3ac4317a401f83e003bde76ca3f0"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.1.c2-rel"

PR = "r1"

DEPENDS += "liblog"

BBCLASSEXTEND = "native"

SRC_URI  = "${SYSTEMCORE_REPO}"

S = "${WORKDIR}/git/libcutils"

EXTRA_OECONF  = " --with-core-includes=${WORKDIR}/git/include"
EXTRA_OECONF += " --with-host-os=${HOST_OS}"
EXTRA_OECONF += " --disable-static"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8017', ' LE_PROPERTIES_ENABLED=true', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8009', ' LE_PROPERTIES_ENABLED=true', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8053', ' LE_PROPERTIES_ENABLED=true', '', d)}"

EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8096', ' LE_PROPERTIES_ENABLED=true', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8098', ' LE_PROPERTIES_ENABLED=true', '', d)}"

PACKAGE_DEBUG_SPLIT_STYLE = 'debug-without-src'
FILES_${PN}-dbg    = "${libdir}/.debug/libcutils.*"
FILES_${PN}        = "${libdir}/libcutils.so.* ${libdir}/pkgconfig/*"
FILES_${PN}-dev    = "${libdir}/libcutils.so ${libdir}/libcutils.la ${includedir}"

do_install_append() {
    install -m 0644 -D ${WORKDIR}/git/include/private/android_filesystem_capability.h ${D}${includedir}/private/android_filesystem_capability.h
    install -m 0644 -D ${WORKDIR}/git/include/private/android_filesystem_config.h ${D}${includedir}/private/android_filesystem_config.h
}
