SRCREV = "919783d4573a3bdad27aca38d5f17a26490a1d2b"
COMPATWIRELESS_REPO = "git://codeaurora.org/platform/external/compat-wireless;branch=mdm"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-the-compile-error-in-LE.3.1.patch;striplevel=6"
SRC_URI += "file://0002-Workaround-to-bring-up-alx-by-fallbacking-to-LE.2.0-driver.patch;striplevel=6"
SRC_URI += "file://0003-Require-IPA-RM-source-when-wakeup-or-plugin-Ethernet.patch;striplevel=6"
