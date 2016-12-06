inherit autotools pkgconfig

DESCRIPTION = "Data Services Open Source"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=3775480a712fc46a69647678acb234cb"

PR = "r1"
DEPENDS += "virtual/kernel glib-2.0"

EXTRA_OECONF = "--with-sanitized-headers=${STAGING_KERNEL_DIR}/usr/include \
                --with-glib"

# Tag LNX.LE.5.3-76132-9x40
SRCREV = "67be864a70f78cab0f526f50ec4c8d65acbba80e"
DATAOSS_REPO ?= "git://codeaurora.org/platform/vendor/qcom-opensource/dataservices;branch=LNX.LE.5.3"

SRC_URI = "${DATAOSS_REPO}"
S = "${WORKDIR}/git"

EXTRA_OEMAKE = "INCLUDES='-I${S}/rmnetctl/inc'"
