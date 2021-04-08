FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# Location of Tufello support patch. 0001-hciattach-add-QCA9377-Tuffello-support.patch
# is coming from public repo, and it is misspelled (Tufello is area of Italian city of Rome).
SRC_URI += "file://0001-hciattach-add-QCA9377-Tuffello-support.patch"
SRC_URI += "file://0001-tufello-support-fixups.patch"
SRC_URI += "file://0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch"
SRC_URI += "file://0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch"
SRC_URI += "${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '4.14%', 'file://0002-hciattach-Tufello-support-fixup-for-kernel-4.14.patch', '', d)}"

# If MODULE_HAS_MAC_ADDR is defined, MAC address stored in NV parameters will be ignored.
# For now, leave it as defined, and we will decide later on, how we are going to configure
# the system.
# I am also defining FW_CONFIG_FILE_PATH for better control outside the source code.
# However, you need to be really careful, because there are some other files which
# would need to be stored in /etc/bluetooth, and this directory would need to exist.
# Note that if you add _PLATFORM_MDM_, that firmware files must be located
# @ /lib/firmware, otherwise in /lib/firmware/qca .
EXTRA_OEMAKE += "\
  CPPFLAGS='-DMODULE_HAS_MAC_ADDR -D_PLATFORM_MDM_ -DFW_CONFIG_FILE_PATH=\"/etc/bluetooth/firmware.conf\"' \
"

# EXTRA_OEMAKE += "\
#  CPPFLAGS='-DMODULE_HAS_MAC_ADDR -DFW_CONFIG_FILE_PATH=\"/etc/bluetooth/firmware.conf\"' \
# "

PACKAGECONFIG_append = " mesh"
PACKAGECONFIG_append = " nfc"

#
# Extra cleanup
#
PACKAGECONFIG[udev] = "--enable-udev,--disable-udev,udev"

# Remove udev dependency. Note that DEPENDS_remove does not work with:
#     PACKAGECONFIG_CONFARGS_append = " --disable-udev"
# even though it should (yet another "learning" experience with Yocto),
# and 'configure' stage will fail.
# So, in order to remove udev deps, we need to use PACKAGECONFIG_remove
# instead.
DEPENDS_remove = "udev"
PACKAGECONFIG_remove = "udev"
