
# Tag LNX.LE.5.3-79002-9x40
SRCREV = "142af782e88bfb242392df2f24cbd3835f8d1784"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=LNX.LE.5.3_rb1.1"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"
