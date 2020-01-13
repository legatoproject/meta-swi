FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://iptables \
            file://iptables.rules \
            file://iptables.ro.rules \
            file://ip6tables \
            file://ip6tables.rules \
            file://ip6tables.ro.rules \
            file://rules.v4 \
            file://rules.v6 \
            file://README \
           "

do_install_append () {
        install -d ${D}${prefix}/local
        install -m 0644 ${WORKDIR}/iptables.rules ${D}${sysconfdir}/
        install -m 0755 ${WORKDIR}/iptables ${D}${sysconfdir}/network/if-pre-up.d
        install -m 0444 ${WORKDIR}/iptables.ro.rules ${D}${prefix}/local/
        install -m 0644 ${WORKDIR}/ip6tables.rules ${D}${sysconfdir}/
        install -m 0755 ${WORKDIR}/ip6tables ${D}${sysconfdir}/network/if-pre-up.d
        install -m 0444 ${WORKDIR}/ip6tables.ro.rules ${D}${prefix}/local/
        install -m 0644 ${WORKDIR}/README ${D}${sysconfdir}/iptables/
}

FILES_${PN} += "${prefix}/*"
