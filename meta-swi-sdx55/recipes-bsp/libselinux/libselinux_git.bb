inherit autotools-brokensep pkgconfig

DESCRIPTION = "Libselinux"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://NOTICE;md5=84b4d2c6ef954a2d4081e775a270d0d0"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "ee539d24828440eda6115da4f300937383c6a98d"
LIBSELINUX_REPO = "git://codeaurora.org/platform/external/libselinux;branch=le-blast.lnx.1.1-rel"

PR = "r0"

DEPENDS = "libpcre libmincrypt liblog libcutils"

FILESPATH =+ "${WORKSPACE}:"
SRC_URI  = "${LIBSELINUX_REPO}"
S = "${WORKDIR}/git"

EXTRA_OECONF = " --with-pcre --with-core-includes=${WORKSPACE}/system/core/include"
