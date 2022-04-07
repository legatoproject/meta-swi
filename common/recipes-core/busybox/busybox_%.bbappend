# look for files in the layer first
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://50default \
                   ${@bb.utils.contains('DISTRO_FEATURES', 'lxc', 'file://lxc.cfg', '', d)} \
                   ${@bb.utils.contains('DISTRO_FEATURES', 'pam', 'file://pam.cfg', '', d)} \
                   file://crond.cfg \
                   file://logrotate_syslog.conf \
                   file://crontabs_root.conf \
                   file://microcom_local_echo_and_ascii_backspace.patch \
                   file://0001-Copy-extended-attributes-if-p-flag-is-provided-to-cp.patch \
                   file://crond-Reduce-log-level-of-start_jobs-debug.patch \
                 "

# Split busybox-cron into a separate package so as to get the start-up scripts through INITSCRIPTS* configuration.
PACKAGES =+ "${PN}-cron"

FILES:${PN}-cron = "${sysconfdir}/init.d/busybox-cron ${sysconfdir}/cron/crontabs/*"

INITSCRIPT_PACKAGES += "${PN}-cron"
INITSCRIPT_NAME:${PN}-cron = "busybox-cron"
INITSCRIPT_PARAMS:${PN}-cron = "start 20 S . stop 80 S ."

INITSCRIPT_PARAMS:${PN}-syslog = "start 20 S . stop 80 S ."

RDEPENDS:${PN}-cron = "busybox"

# Bring in the busybox-cron and logrotate package to rootfs.
RDEPENDS:${PN}-syslog += "busybox-cron logrotate"

PACKAGECONFIG += "${@bb.utils.filter('DISTRO_FEATURES', 'pam', d)}"
PACKAGECONFIG[pam] = ",,libpam,libpam"

do_install:append() {
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
