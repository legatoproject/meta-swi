# Look at this directlry first.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://rules.v4 \
            file://rules.v6 \
            file://rules-qemu.v4 \
            file://rules-qemu.v6 \
           "

do_install:append() {
    [[ "${MACHINE}" == "*qemu*" ]] && qemu="-qemu" || qemu=

    install -d ${D}${sysconfdir}/iptables
    install -m 0644 ${WORKDIR}/rules${qemu}.v4 -D ${D}${sysconfdir}/iptables/rules.v4
    install -m 0644 ${WORKDIR}/rules${qemu}.v6 -D ${D}${sysconfdir}/iptables/rules.v6
}
