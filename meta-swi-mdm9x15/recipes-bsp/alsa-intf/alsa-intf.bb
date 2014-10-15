inherit autotools

DESCRIPTION = "ALSA Framework Library"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
DEPENDS = "virtual/kernel acdbloader glib-2.0"
PR = "r0"

SRC_URI = "file://mm-audio.tar.bz2"
SRC_URI += "file://0001-SBM-16534-12181-aplay-arec-amix-consume-too-much-CPU-resource.patch"
prefix="/etc"

S = "${WORKDIR}/mm-audio"

EXTRA_OECONF += "--prefix=/etc \
                 --with-sanitized-headers=${STAGING_KERNEL_DIR}/include \
                 --with-glib"

FILES_${PN} += "${prefix}/snd_soc_msm/*"
