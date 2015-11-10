FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

POWERAPP_REPO = "git://codeaurora.org/platform/system/core;branch=penguin"
SRC_URI += "file://0001-mdm9x15-Remove-startup-errors.patch;striplevel=2"
SRC_URI += "file://0002-trac-1219-Switch-sysV-init-to-busybox-style-init.patch"
