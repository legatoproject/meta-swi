
# Tag LE.BR.1.2.1-44100-9x07
SRCREV = "1ec3812e95b2541dce8a1a0130c29be766edae99"
# Tag LE.BR.1.2.1-59300-9x07
SRCREV_swi-mdm9x28-ar758x = "1ec3812e95b2541dce8a1a0130c29be766edae99"

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
