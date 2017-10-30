
# Tag LE.BR.1.2.1-44100-9x07
SRCREV = "95852f8b85a9b2d190b395aaf9621fb6cca90dc6"
# Tag LE.BR.1.2.1-59300-9x07
SRCREV_swi-mdm9x28-ar758x = "dd72ed8c45bb873f7159a94fb30269b6f1a216af"

SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append_swi-mdm9x28 += "file://start_power_config.patch"
SRC_URI_append_swi-mdm9x28-ar758x += "file://start_power_config_ar758x.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"

