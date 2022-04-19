inherit autotools pkgconfig

DESCRIPTION = "Data Services Open Source"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"

PR = "r1"
DEPENDS += "virtual/kernel glib-2.0"

EXTRA_OECONF = "--with-sanitized-headers=${STAGING_DIR_TARGET}${KERNEL_SRC_PATH}/usr/include \
                --with-glib"

# Tag LE.UM.1.1-23600-9x07
SRCREV = "21e5e4454102134ee837827edbf6a390da0fd7ef"
DATAOSS_REPO ?= "git://codeaurora.org/platform/vendor/qcom-opensource/dataservices;branch=master"

SRC_URI = "${DATAOSS_REPO} file://static-inline.patch"
S = "${WORKDIR}/git"

EXTRA_OEMAKE = "INCLUDES='-I${S}/rmnetctl/inc'"
