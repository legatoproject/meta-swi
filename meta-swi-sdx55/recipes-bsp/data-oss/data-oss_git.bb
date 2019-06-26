inherit autotools pkgconfig

DESCRIPTION = "Data Services Open Source"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=3775480a712fc46a69647678acb234cb"

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
