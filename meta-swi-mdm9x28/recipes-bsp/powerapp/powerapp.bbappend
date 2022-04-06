
# Tag LE.BR.1.2.1-44100-9x07
SRCREV = "95852f8b85a9b2d190b395aaf9621fb6cca90dc6"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "${SYSTEMCORE_REPO}"
SRC_URI += "file://start_power_config.patch \
            file://mdm9206_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"

