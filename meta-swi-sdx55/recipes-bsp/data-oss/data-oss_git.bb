inherit autotools pkgconfig

DESCRIPTION = "Data Services Open Source"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"

PR = "r4"
DEPENDS += "virtual/kernel glib-2.0"

EXTRA_OECONF = "--with-sanitized-headers=${STAGING_KERNEL_BUILDDIR}/usr/include \
                --with-glib"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "6e977838e645a1819e972a1cda141d26efc00f15"
DATAOSS_REPO ?= "git://codeaurora.org/platform/vendor/qcom-opensource/dataservices;branch=data.lnx.1.1"

SRC_URI = "${DATAOSS_REPO}"
S = "${WORKDIR}/git"

EXTRA_OEMAKE = "INCLUDES='-I${S}/rmnetctl/inc'"
