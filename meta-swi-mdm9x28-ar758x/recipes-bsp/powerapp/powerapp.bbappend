
# Tag LE.UM.1.2-15100-9x07
SRCREV = "0918d945560b3ac4317a401f83e003bde76ca3f0"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.1.c2-rel"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "${SYSTEMCORE_REPO}"
SRC_URI += "file://start_power_config.patch"

