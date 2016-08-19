SRCREV = "919783d4573a3bdad27aca38d5f17a26490a1d2b"
COMPATWIRELESS_REPO = "git://codeaurora.org/platform/external/compat-wireless;branch=mdm"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Bring-up-alx-driver-on-Qualcomm-LE.3.1.rb.1.1-stack.patch;striplevel=6"