# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)


    # Handle versions < 1.29.2
    if re.match('1.2[0-8]', pv):
        d.setVar('SRC_URI', srcuri + \
                 ' file://microcom_local_echo_and_ascii_backspace_1.27.2.patch' \
                 ' file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch')
    else:
        d.setVar('SRC_URI', srcuri + \
                 ' file://microcom_local_echo_and_ascii_backspace_1.29.2.patch' \
                 ' file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp_1.29.2.patch')
}

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

do_install_append() {
  # These conflict with initscripts
  rm -rf ${D}${sysconfdir}/init.d/rcS
  rm -rf ${D}${sysconfdir}/init.d/rcK
  rm -rf ${D}${sysconfdir}/inittab
}
