
# Tag LE.BR.1.3.1-04810-9x50
SRCREV = "cdad155a747c1ed679e0360b868f7e71d67795e6"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.0-rel"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://start_power_config.patch"

SANITIZED_HEADERS = "${STAGING_KERNEL_DIR}/usr/include"

