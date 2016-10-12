
# Tag LE.BR.1.2.1-64400-9x07
SRCREV = "d04220ee2b1b46e19369137117bf82cd92e5420a"
REBOOTD_REPO = "git://codeaurora.org/quic/le/mdm/reboot-daemon;branch=master"

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
