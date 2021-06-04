FILESEXTRAPATHS_prepend := "${THISDIR}/files:"


SRC_URI += "file://iptables \
            file://iptables.rules \
            file://iptables.ro.rules \
            file://interfaces_fx30 \
            file://ip6tables \
            file://ip6tables.rules \
            file://ip6tables.ro.rules \
           "

do_install_append () {
        install -d ${D}${prefix}/local
        install -m 0644 ${WORKDIR}/iptables.rules ${D}${sysconfdir}/
        install -m 0644 ${WORKDIR}/iptables.ro.rules ${D}${prefix}/local/
        install -m 0755 ${WORKDIR}/iptables ${D}${sysconfdir}/network/if-pre-up.d
        # There appears to be a race condition when the interfaces file is fetched
        # So install the FX30 version afterwards to ensure the correct one is included
        install -m 0644 ${WORKDIR}/interfaces_fx30 ${D}${sysconfdir}/network/interfaces
        install -m 0644 ${WORKDIR}/ip6tables.rules ${D}${sysconfdir}/
        install -m 0644 ${WORKDIR}/ip6tables.ro.rules ${D}${prefix}/local/
        install -m 0755 ${WORKDIR}/ip6tables ${D}${sysconfdir}/network/if-pre-up.d
}

FILES_${PN} += "${prefix}/*"
