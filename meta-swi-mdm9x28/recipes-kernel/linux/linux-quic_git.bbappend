FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "${@bb.utils.contains('ENABLE_QCA9377', '1', 'file://0001-QCA9377-Support-enable-config.patch', '', d)}"
SRC_URI += "${@bb.utils.contains('ENABLE_QCA9377', '1', 'file://0003-QCA9377-Support-ignore-resource-error.patch', '', d)}"
