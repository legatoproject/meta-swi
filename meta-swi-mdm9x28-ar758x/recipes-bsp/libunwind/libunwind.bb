inherit autotools-brokensep pkgconfig

DESCRIPTION = "Libunwind"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/external/libunwind/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "5666bf1198f2205c3825375cdeb9a92fa2baff34"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/external/libunwind;branch=le-blast.lnx.1.1.c2-rel"

DEPENDS = "libatomic-ops"

PR = "r0"
SRC_URI = "${SYSTEMCORE_REPO}"
S = "${WORKDIR}/git"
