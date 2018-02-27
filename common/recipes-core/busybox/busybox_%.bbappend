# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://microcom_local_echo_and_ascii_backspace.patch \
            file://mdev-dev-bus-usb.patch \
            file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

