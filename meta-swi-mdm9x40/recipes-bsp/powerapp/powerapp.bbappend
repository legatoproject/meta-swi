# Tag LNX.LE.5.3-76324-9x40
SRCREV = "29256d16efa4c251dbf644034882fe95b27b7f07"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"