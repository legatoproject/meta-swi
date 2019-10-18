#
# These packages are needed for FX30.
#

#================
# QCA9377 support
#================

# Kernel module
IMAGE_INSTALL_append = " qcacld-hl"

# Init script
IMAGE_INSTALL_append = " sierra-init-qca9377"

# Bluetooth Bluez support
IMAGE_INSTALL_append = " bluez5"
IMAGE_INSTALL_append = " qca9377-bt-firmware"

#
# These packages are not needed for FX30.
#
# IMAGE_INSTALL_remove = "package-name"
