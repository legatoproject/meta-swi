# Tag LE.BR.1.2.1-64400-9x07
SRCREV = "e905909728462393cef12b5e6802e708957037fe"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=master"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"
