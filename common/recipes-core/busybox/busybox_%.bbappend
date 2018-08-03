# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)


    # Handle versions < 1.27.2
    if re.match('1.2[0-6]', pv):
        d.setVar('SRC_URI', srcuri + ' file://microcom_local_echo_and_ascii_backspace.patch' \
                                     ' file://mdev-dev-bus-usb.patch')
    else:
        d.setVar('SRC_URI', srcuri + ' file://microcom_local_echo_and_ascii_backspace_1.27.2.patch')
}

SRC_URI_append = " file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

