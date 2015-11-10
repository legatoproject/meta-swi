
# Tag LNX.LE.5.1-66215-9x40
#SRCREV = "eb356a1ff24619faa656985db376e4c8ffbaa2a4"
#SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.1_rb1.6"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
#SRC_URI += "file://0001-Fix-typo-in-configure-ac.patch"

#do_install_append() {
#   ln -s  /sbin/usb/compositions/9025 ${D}${base_sbindir}/usb/boot_hsusb_composition
#   ln -s  /sbin/usb/compositions/empty ${D}${base_sbindir}/usb/boot_hsic_composition
#}
