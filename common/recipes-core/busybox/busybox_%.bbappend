# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch \
                   file://microcom_local_echo_and_ascii_backspace_1.27.2.patch"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

do_install_append() {
  # These conflict with initscripts
  rm -rf ${D}${sysconfdir}/init.d/rcS
  rm -rf ${D}${sysconfdir}/init.d/rcK
  rm -rf ${D}${sysconfdir}/inittab
}
