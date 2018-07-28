# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://restartNMEA \
           file://ecm.conf \
           file://dnsmasq.ecm.conf \
           "

do_install_append() {
    # Replace the generic mdm9xxx restartNMEA with an mdm9x15 variant
    install -m 0755 ${WORKDIR}/restartNMEA -D ${D}${sbindir}/restartNMEA
    install -D -m 0644 ${WORKDIR}/ecm.conf ${D}${sysconfdir}/legato/ecm.conf
    install -D -m 0644 ${WORKDIR}/dnsmasq.ecm.conf ${D}${sysconfdir}/dnsmasq.d/dnsmasq.ecm.conf
}
