# Look at this directlry first.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://rules.v4 \
            file://rules.v6 \
           "

do_install_append() {
    install -d ${D}${sysconfdir}/iptables
    install -m 0644 ${WORKDIR}/rules.v4 -D ${D}${sysconfdir}/iptables/rules.v4
    install -m 0644 ${WORKDIR}/rules.v6 -D ${D}${sysconfdir}/iptables/rules.v6

    if [[ "${MACHINE}" == "*qemu*" ]]; then
        sed -i 's/@ECM_IF@/eth0/g' ${D}${sysconfdir}/iptables/rules.v4
        sed -i 's/@ECM_IF@/eth0/g' ${D}${sysconfdir}/iptables/rules.v6
    fi
}
