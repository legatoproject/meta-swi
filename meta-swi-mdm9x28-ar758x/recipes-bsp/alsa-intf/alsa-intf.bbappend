
# Tag LE.UM.1.2-15100-9x07
SRCREV = "c7ceae905b1b26e5df6b7eed28ece735f6bf3e28"
ALSAINTF_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/kernel-tests/mm-audio;branch=audio-mdm.lnx.1.0.c2-rel"

DEPENDS = "acdbloader glib-2.0"

EXTRA_OECONF += "--with-acdb"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "${ALSAINTF_REPO} \
            file://0001-Fix-build-without-QC-headers.patch \
            file://0002-Fix-build-without-acdb-loader.patch \
            file://0003-mm-audio-offer-aplay-arec-amix-dynamic-libraries.patch \
            file://0004-Add-backtrace-compiling-options.patch \
            file://0005-Yocto-2.2-fixes.patch"
