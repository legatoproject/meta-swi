# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_1.24.1_append = " file://microcom_local_echo_and_ascii_backspace.patch \
                          file://mdev-dev-bus-usb.patch"

SRC_URI_1.27.2_append = "file://microcom_local_echo_and_ascii_backspace_1.27.2.patch"

SRC_URI_append = " file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

