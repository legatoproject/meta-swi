# Tag LE.BR.1.3.1-04810-9x50
SRCREV = "440ddaf9d75e398848bdb4d0757967d5403945e8"
LIBHARDWARE_REPO = "git://codeaurora.org/platform/hardware/libhardware;branch=oe_master"

do_install_append() {
    install -m 0644 ${S}/include/hardware/fused_location.h -D ${D}${includedir}/hardware/fused_location.h
}
