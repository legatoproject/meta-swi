inherit autotools-brokensep pkgconfig

DESCRIPTION = "Build Android libion"
HOMEPAGE = "http://developer.android.com/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

PR = "r1"

# Tag LE.UM.3.4.2-01600-9x07
SRCREV = "f4f05770cc09ab0e1bcfbb516173e5b3d80a847c"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LE.UM.3.4.2.r1.10"

SRC_URI  = "${SYSTEMCORE_REPO}"

S = "${WORKDIR}/git/libion"
DEPENDS += "virtual/kernel system-core"

EXTRA_OECONF += " --disable-static"
EXTRA_OECONF += "${@bb.utils.contains_any('PREFERRED_VERSION_linux-msm', '3.18 4.4 4.9', '--with-legacyion', '', d)}"
EXTRA_OECONF += "--with-sanitized-headers=${STAGING_KERNEL_BUILDDIR}/usr/include"

PACKAGES +="${PN}-test-bin"

FILES_${PN}     = "${libdir}/pkgconfig/* ${libdir}/* ${sysconfdir}/*"
FILES_${PN}-test-bin = "${base_bindir}/*"
