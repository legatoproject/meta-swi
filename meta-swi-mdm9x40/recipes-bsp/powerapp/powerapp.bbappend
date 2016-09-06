# Tag LNX.LE.5.3-79003-9x40
SRCREV = "75510472603f316d045c917a799ec4b7562ff1f0"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3_rb1.2"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"