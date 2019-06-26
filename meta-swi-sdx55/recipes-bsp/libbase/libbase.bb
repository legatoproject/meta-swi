inherit autotools pkgconfig

DESCRIPTION = "Build LE libbase"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "f4d07fb7ca9244ace3bf1061388694846f740006"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.2"

PR = "r1"

SRC_URI  = "${SYSTEMCORE_REPO}"

S = "${WORKDIR}/git/base"

EXTRA_OECONF += "--with-core-sourcedir=${WORKDIR}/git"

DEPENDS += "libcutils libselinux"

BBCLASSEXTEND = "native"

FILES_${PN}-dbg    = "${libdir}/.debug/libbase.*"
FILES_${PN}        = "${libdir}/libbase.so.* ${libdir}/pkgconfig/*"
FILES_${PN}-dev    = "${libdir}/libbase.so ${libdir}/libbase.la ${includedir}"
