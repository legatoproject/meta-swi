
# Tag LNX.LE.5.3-9x40
SRCREV = "d4a1a41203f0f3f10a9f31538254bd80037e9da2"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"
