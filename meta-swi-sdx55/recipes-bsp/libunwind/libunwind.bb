inherit autotools-brokensep pkgconfig

DESCRIPTION = "Libunwind"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/external/libunwind/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "7ae792b4d98fb654b494675ba0f541bf2e664d55"
LIBUNWIND_REPO = "git://codeaurora.org/platform/external/libunwind;branch=le-blast.lnx.1.2"

DEPENDS = "libatomic-ops"

PR = "r0"
SRC_URI = "${LIBUNWIND_REPO}"
S = "${WORKDIR}/git"
