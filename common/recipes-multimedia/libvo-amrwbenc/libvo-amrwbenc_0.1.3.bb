SMMARY = "VisualOn AMR-WB Audio Encoder"
DESCRIPTION = "VisualOn AMR-WB audio encoder library."
SECTION = "libs/multimedia"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PR = "r0"

SRC_URI = "${SOURCEFORGE_MIRROR}/opencore-amr/vo-amrwbenc-${PV}.tar.gz"
SRC_URI[md5sum] = "f63bb92bde0b1583cb3cb344c12922e0"
SRC_URI[sha256sum] = "5652b391e0f0e296417b841b02987d3fd33e6c0af342c69542cbb016a71d9d4e"

S = "${WORKDIR}/vo-amrwbenc-${PV}"

inherit autotools pkgconfig

