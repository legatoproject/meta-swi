
# Tag LNX.LE.5.3-76324-9x40
SRCREV = "9cc863d799891aba8ac6af6ab761a2a1e6efea10"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=LNX.LE.5.3_1"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"
SRC_URI += "file://0002-mm-audio-offer-aplay-arec-amix-dynamic-libraries.patch"
SRC_URI += "file://0003-Add-backtrace-compiling-options.patch"
SRC_URI += "file://0005-Yocto-2.2-fixes.patch"

