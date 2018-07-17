RDEPENDS_${PN} += "powerapp"
RDEPENDS_${PN} += "powerapp-powerconfig"
RDEPENDS_${PN} += "powerapp-reboot"
RDEPENDS_${PN} += "powerapp-shutdown"
RDEPENDS_${PN} += "reboot-daemon"
RDEPENDS_${PN} += "system-core-adbd"
RDEPENDS_${PN} += "system-core-usb"

# When compiling the "system-core.bb", would package-slipt "system-core-liblog" and
# "system-core-libcutils", but the "system-core_2.0.bb" which was used in LE.2.0.1
# on ar758x doesn't package-slipt "system-core-liblog" and "system-core-libcutils".
# At the same time, in LE.2.0.1 on ar758x, had added the "liblog.bb" and "libcutils.bb"
# to compile their package.
# Here was compatible with different versions of the "system-core". When using the
# 2.0 version, don't add "RDEPENDS_${PN} += "system-core-libcutils" and
# "RDEPENDS_${PN} += "system-core-liblog" to here, otherwise, add them to here.
RDEPENDS_${PN} += "${@bb.utils.contains('PREFERRED_VERSION_system-core', '2.0', '', 'system-core-liblog system-core-libcutils', d)}"
