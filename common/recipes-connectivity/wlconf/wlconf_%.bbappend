# Choose a conf binary aligned to the kernel version.
def wl_conf_bin(d):
    kernel_provider = d.getVar("PREFERRED_PROVIDER_virtual/kernel", True)
    kernel_version = d.getVar('PREFERRED_VERSION_%s' % kernel_provider, True)
    if kernel_version == "4.14%":
        # Aligned to Tag: R8.7-SP3 (8.7.3)
        return "wl18xx-conf_8.7.3.bin"
    else:
        # Aligned to Tag: ol_r8.a9.17
        return "wl18xx-conf.bin"

WLCONF_BIN = '${@wl_conf_bin(d)}'

# Install only the conf binary into rootfs
SRC_URI = "file://${WLCONF_BIN}"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}/lib/firmware/ti-connectivity
    install -m 0644 ${WORKDIR}/${WLCONF_BIN} ${D}/lib/firmware/ti-connectivity/wl18xx-conf.bin
}

FILES:${PN} = "/lib/firmware/ti-connectivity/wl18xx-conf.bin"
