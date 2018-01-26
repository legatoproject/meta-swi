

# Tag LE.BR.1.2.1-59300-9x07
SRCREV = "dd72ed8c45bb873f7159a94fb30269b6f1a216af"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "${SYSTEMCORE_REPO} \
          file://start_power_config.patch"

