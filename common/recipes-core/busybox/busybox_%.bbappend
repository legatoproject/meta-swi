# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)


    # Handle versions < 1.27.2
    if re.match('1.2[0-6]', pv):
        d.setVar('SRC_URI', srcuri + \
                 ' file://microcom_local_echo_and_ascii_backspace.patch' \
                 ' file://mdev-dev-bus-usb.patch' \
                 ' file://0001-modutils-support-finit_module-syscall.patch' \
                 ' file://busybox-tar-add-IF_FEATURE_-checks.patch' \
                 ' file://0001-iproute-support-scope-.-Closes-8561.patch' \
                 ' file://0001-ip-fix-an-improper-optimization-req.r.rtm_scope-may-.patch' \
                 ' file://Fix_semop_interrupted.patch' \
                 ' file://CVE-2017-16544.patch')
    else:
        d.setVar('SRC_URI', srcuri + \
                 ' file://microcom_local_echo_and_ascii_backspace_1.27.2.patch')
}

SRC_URI_append = " file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

do_install_append() {
  # These conflict with initscripts
  rm -rf ${D}${sysconfdir}/init.d/rcS
  rm -rf ${D}${sysconfdir}/init.d/rcK
  rm -rf ${D}${sysconfdir}/inittab
}

RDEPENDS_${PN} = "${@["", "busybox-inittab"][(d.getVar('VIRTUAL-RUNTIME_init_manager', True) == 'busybox')]}"
