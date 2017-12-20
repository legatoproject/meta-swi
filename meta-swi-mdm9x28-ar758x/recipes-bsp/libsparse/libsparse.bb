inherit autotools pkgconfig

DESCRIPTION = "Build Android libsprase"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "0918d945560b3ac4317a401f83e003bde76ca3f0"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.1.c2-rel"

PR = "r0"

DEPENDS += "zlib"
SRC_URI  = "${SYSTEMCORE_REPO}"

S = "${WORKDIR}/git/libsparse"
