
# Tag LE.BR.1.3.1-04810-9x50
SRCREV = "e312fbda7e61d82ddce34b12e34cf46ad8d4e549"
REBOOTD_REPO = "git://codeaurora.org/quic/le/mdm/reboot-daemon;branch=LE.BR.1.3.1_rb1.27"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI +="file://start_rebootdaemon"

INITSCRIPT_NAME = "rebootdaemon"

inherit update-rc.d

do_install_append() {
        install -m 0755 ${WORKDIR}/start_rebootdaemon -D ${D}${sysconfdir}/init.d/rebootdaemon
}

pkg_postinst_${PN} () {
        [ -n "$D" ] && OPT="-r $D" || OPT="-s"
        update-rc.d $OPT -f rebootdaemon remove
        update-rc.d $OPT rebootdaemon start 35 S . stop 65 S .
}
