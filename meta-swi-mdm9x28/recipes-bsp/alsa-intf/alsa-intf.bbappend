# Tag LE.UM.1.1-23600-9x07
SRCREV = "eac125d36533b535985713e7c64136e035b7a300"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=master"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-QC-headers.patch"
SRC_URI += "file://Fix-codec-High-cpu-load.patch"
SRC_URI += "file://0003-mm-audio-offer-aplay-arec-amix-dynamic-libraries.patch"
SRC_URI += "file://0004-Add-backtrace-compiling-options.patch"
SRC_URI += "file://0005-Yocto-2.2-fixes.patch"
SRC_URI += "file://0006-Wait-for-Audio-stream-to-end.patch"

