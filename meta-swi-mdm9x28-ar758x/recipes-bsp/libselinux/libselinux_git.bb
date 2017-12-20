inherit autotools-brokensep pkgconfig

DESCRIPTION = "Libselinux"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/external/libselinux/"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=b3597d12946881e13cb3b548d1173851"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "ee539d24828440eda6115da4f300937383c6a98d"
LIBSELINUX_REPO = "git://codeaurora.org/platform/external/libselinux;branch=le-blast.lnx.1.1.c2-rel"

PR = "r0"

DEPENDS = "libpcre libmincrypt liblog libcutils"

SRC_URI  = "${LIBSELINUX_REPO}"

S = "${WORKDIR}/git"

EXTRA_OECONF = " --with-pcre"
EXTRA_OECONF += " --with-sanitized-headers=${STAGING_DIR_TARGET}${KERNEL_SRC_PATH}/usr/include"
