SUMMARY = "OpenCORE AMR Audio Codec"
DESCRIPTION = "OpenCORE AMR-NB and AMR-WB audio codec library."
SECTION = "libs/multimedia"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
PR = "r0"

SRC_URI = "${SOURCEFORGE_MIRROR}/opencore-amr/opencore-amr-${PV}.tar.gz"
SRC_URI[md5sum] = "09d2c5dfb43a9f6e9fec8b1ae678e725"
SRC_URI[sha256sum] = "106bf811c1f36444d7671d8fd2589f8b2e0cca58a2c764da62ffc4a070595385"

S = "${WORKDIR}/opencore-amr-${PV}"

inherit autotools pkgconfig

EXTRA_OECONF = " \
    --enable-gcc-armv5 \
"

