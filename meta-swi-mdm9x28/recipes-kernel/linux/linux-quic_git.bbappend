FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "${@bb.utils.contains('ENABLE_QCA9377', '1', 'file://0001-QCA9377-Support-enable-config.patch', '', d)}"
SRC_URI += "${@bb.utils.contains('ENABLE_QCA9377', '1', 'file://0001-linux-kernel-Fix-kernel-crash-if-QCA9377-is-enabled.patch', '', d)}"
