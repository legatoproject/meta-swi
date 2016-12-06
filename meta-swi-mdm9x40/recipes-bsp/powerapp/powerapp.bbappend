# Tag LNX.LE.5.3-76132-9x40
SRCREV = "af083a9e88f2e4b89437fa2508041fd96ecd4d45"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"