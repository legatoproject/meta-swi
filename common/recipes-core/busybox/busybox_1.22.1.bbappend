# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

do_install_append() {
    # Modify the busybox command line
    sed --in-place=bak -e "s?start-stop-daemon -S -b -n syslogd -a /sbin/syslogd -- -n \$SYSLOG_ARGS?start-stop-daemon -S -b -n syslogd -a /sbin/syslogd -- -C200?" ${D}${sysconfdir}/init.d/syslog.busybox
}

