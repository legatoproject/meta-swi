inherit autotools pkgconfig

DESCRIPTION = "Build Android libcutils"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "f4d07fb7ca9244ace3bf1061388694846f740006"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.2"

PR = "r1"

DEPENDS += "liblog"

BBCLASSEXTEND = "native"

SRC_URI  = "${SYSTEMCORE_REPO}"

S = "${WORKDIR}/git/libcutils"

EXTRA_OECONF  = " --with-core-includes=${WORKDIR}/git/include"
EXTRA_OECONF += " --with-host-os=${HOST_OS}"
EXTRA_OECONF += " --disable-static"

PROVIDES = "system-core-libcutils"
RPROVIDES_${PN} = "system-core-libcutils"

PACKAGE_DEBUG_SPLIT_STYLE = 'debug-without-src'
FILES_${PN}-dbg    = "${libdir}/.debug/libcutils.*"
FILES_${PN}        = "${libdir}/libcutils.so.* ${libdir}/pkgconfig/*"
FILES_${PN}-dev    = "${libdir}/libcutils.so ${libdir}/libcutils.la ${includedir}"
