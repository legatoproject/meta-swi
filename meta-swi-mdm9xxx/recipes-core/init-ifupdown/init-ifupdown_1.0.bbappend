# Look at this directlry first.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

INITSCRIPT_PARAMS = "start 20 S . stop 80 S ."

SRC_URI += "file://rules.v4 \
            file://rules.v6 \
           "

do_install_append() {
    install -d ${D}${sysconfdir}/iptables
    install -m 0644 ${WORKDIR}/rules.v4 -D ${D}${sysconfdir}/iptables/rules.v4
    install -m 0644 ${WORKDIR}/rules.v6 -D ${D}${sysconfdir}/iptables/rules.v6
}
