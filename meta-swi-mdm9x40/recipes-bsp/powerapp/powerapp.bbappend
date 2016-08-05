# Tag LNX.LE.5.3-9x40
SRCREV = "1ed3c52d291a5d48288061a1f5d8a3fa19d465de"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3_rb1.1"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"