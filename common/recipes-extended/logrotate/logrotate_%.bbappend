# Integrate with busybox-cron, instead of cronie package.
# Keep logrotate script in /usr/sbin to be used by crontabs rather than
# keeping at /etc/cron.daily.
do_install_append () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        rm -rf ${D}${sysconfdir}/cron.daily
        install -p -m 0755 ${S}/examples/logrotate.cron ${D}${sbindir}/logrotate.sh
    fi
}
