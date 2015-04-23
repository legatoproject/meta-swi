inherit autotools

DESCRIPTION = "ALSA Framework Library"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/vendor/qcom-opensource/kernel-tests/mm-audio"
DEPENDS = "virtual/kernel acdbloader glib-2.0"
PR = "r1"

SRC_URI  = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;tag=M9615AAAARNLZA1713006;branch=ics_strawberry"
SRC_URI += "file://0001-SBM-16534-12181-aplay-arec-amix-consume-too-much-CPU-resource.patch"
SRC_URI += "file://0002-SBM-17175-optimize-aplay-arec.patch"
SRC_URI += "file://0003-SBM-17419-audio-not-work-with-i2s.patch"
SRC_URI += "file://0004-Fix-build-without-QC-headers.patch"
prefix="/etc"

S = "${WORKDIR}/git"

EXTRA_OECONF += "--prefix=/etc \
                 --with-sanitized-headers=${STAGING_KERNEL_DIR}/include \
                 --with-glib"

FILES_${PN} += "${prefix}/snd_soc_msm/*"
