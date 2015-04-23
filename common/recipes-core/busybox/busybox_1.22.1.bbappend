# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

INITSCRIPT_PARAMS_${PN}-syslog = "start 20 S . stop 80 S ."
INITSCRIPT_PARAMS_${PN}-hwclock = "start 20 S . stop 80 S ."

do_install_append() {
    # Modify the busybox command line
    sed --in-place=bak -e "s?start-stop-daemon -S -b -n syslogd -a /sbin/syslogd -- -n \$SYSLOG_ARGS?start-stop-daemon -S -b -n syslogd -a /sbin/syslogd -- -C200?" ${D}${sysconfdir}/init.d/syslog.busybox
}

