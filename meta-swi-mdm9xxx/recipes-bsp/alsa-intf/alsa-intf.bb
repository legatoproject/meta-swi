inherit autotools pkgconfig

DESCRIPTION = "ALSA Framework Library"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/vendor/qcom-opensource/kernel-tests/mm-audio"
DEPENDS = "virtual/kernel acdbloader glib-2.0"
PR = "r1"

# Tag M9615AAAARNLZA1713006
SRCREV = "e9a91a6cbea03dcd8cbd97cf50844ea3e557790a"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=ics_strawberry"

SRC_URI  = "${ALSAINTF_REPO}"
prefix="/etc"

S = "${WORKDIR}/git"

EXTRA_OECONF += "--prefix=/etc \
                 --with-sanitized-headers=${STAGING_KERNEL_DIR}/include \
                 --with-glib"

FILES_${PN} += "${prefix}/snd_soc_msm/*"
