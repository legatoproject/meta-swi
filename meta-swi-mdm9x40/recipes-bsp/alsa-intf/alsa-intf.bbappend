
# Tag LNX.LE.5.3-79003-9x40
SRCREV = "9cc863d799891aba8ac6af6ab761a2a1e6efea10"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=LNX.LE.5.3_rb1.2"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"
