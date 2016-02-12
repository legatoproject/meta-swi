
# Tag LNX.LE.5.1-66221-9x40
SRCREV = "58224c9d4b98ec20d10f3bb0ce92bfb30c0ff565"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=LNX.LE.5.1_rb1.10"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"
