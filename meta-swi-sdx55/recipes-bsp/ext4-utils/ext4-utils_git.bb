inherit autotools pkgconfig

DESCRIPTION = "EXT4 UTILS"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/extras/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "8ef7dae5e1a207c4683e7ea3ee534ea94d13787a"
SYSTEMEXTRA_REPO = "git://codeaurora.org/platform/system/extras;branch=le-blast.lnx.1.2"

PR = "r1"

DEPENDS = "libselinux libsparse libcutils libpcre"

SRC_URI  = "${SYSTEMEXTRA_REPO}"

S = "${WORKDIR}/git/ext4_utils"

CPPFLAGS += "-I${STAGING_INCDIR}/libselinux"
CPPFLAGS += "-I${STAGING_INCDIR}/cutils"
