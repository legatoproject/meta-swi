# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://50default \
                   ${@bb.utils.contains('DISTRO_FEATURES', 'lxc', 'file://lxc.cfg', '', d)} \
                   ${@bb.utils.contains('DISTRO_FEATURES', 'pam', 'file://pam.cfg', '', d)} \
                   file://crond.cfg \
                   file://logrotate_syslog.conf \
                   file://crontabs_root.conf \
                 "

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
                 ' file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp_1.29.2.patch' \
                 ' file://crond-Reduce-log-level-of-start_jobs-debug.patch')
}

# Split busybox-cron into a separate package so as to get the start-up scripts through INITSCRIPTS* configuration.
PACKAGES =+ "${PN}-cron"

FILES_${PN}-cron = "${sysconfdir}/init.d/busybox-cron ${sysconfdir}/cron/crontabs/*"

INITSCRIPT_PACKAGES += "${PN}-cron"
INITSCRIPT_NAME_${PN}-cron = "busybox-cron"
INITSCRIPT_PARAMS_${PN}-cron = "start 20 S . stop 80 S ."

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."

RDEPENDS_${PN}-cron = "busybox"

# Bring in the busybox-cron and logrotate package to rootfs.
RDEPENDS_${PN}-syslog += "busybox-cron logrotate"

PACKAGECONFIG += "${@bb.utils.filter('DISTRO_FEATURES', 'pam', d)}"
PACKAGECONFIG[pam] = ",,libpam,libpam"

do_install_append() {
    # These conflict with initscripts
    rm -rf ${D}${sysconfdir}/init.d/rcS
    rm -rf ${D}${sysconfdir}/init.d/rcK
    rm -rf ${D}${sysconfdir}/inittab

    # Add udhcpc related stuff.
    install -m 0755 ${WORKDIR}/50default -D ${D}${sysconfdir}/udhcpc.d/50default

    # Install logrotate configuration for persistent logs.
    install -d ${D}${sysconfdir}/logrotate.d
    if grep -q "CONFIG_SYSLOGD=y" ${B}/.config; then
        install -m 0755 ${WORKDIR}/logrotate_syslog.conf ${D}${sysconfdir}/logrotate.d/syslog
    fi

    # Install crontabs configuration
    install -d ${D}${sysconfdir}/cron/crontabs
    if grep -q "CONFIG_CROND=y" ${B}/.config; then
        install -m 0755 ${WORKDIR}/crontabs_root.conf ${D}${sysconfdir}/cron/crontabs/root
    fi
}
