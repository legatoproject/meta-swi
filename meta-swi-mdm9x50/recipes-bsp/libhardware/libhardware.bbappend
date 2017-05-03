# Tag LE.BR.1.3.1-05310-9x50
SRCREV = "dba1fc2f7ede14e7f6d3ca862138fbcd74c57e62"
LIBHARDWARE_REPO = "git://codeaurora.org/platform/hardware/libhardware;branch=le-blast.lnx.1.0-rel"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://autotools2.patch"

do_install_append() {
    install -m 0644 ${S}/include/hardware/fused_location.h -D ${D}${includedir}/hardware/fused_location.h
}
