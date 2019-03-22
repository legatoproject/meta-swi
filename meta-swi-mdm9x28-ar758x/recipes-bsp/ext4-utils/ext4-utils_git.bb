inherit autotools pkgconfig

DESCRIPTION = "EXT4 UTILS"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/extras/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "f487740f037174e09879c3e0dd7a1bae17b39f06"
SYSTEMEXTRA_REPO = "git://codeaurora.org/platform/system/extras;branch=le-blast.lnx.1.1.c2-rel"

PR = "r1"

DEPENDS = "libselinux libsparse libcutils libpcre"

SRC_URI  = "${SYSTEMEXTRA_REPO}"

S = "${WORKDIR}/git/ext4_utils"

CPPFLAGS += "-I${STAGING_INCDIR}/libselinux"
CPPFLAGS += "-I${STAGING_INCDIR}/cutils"
