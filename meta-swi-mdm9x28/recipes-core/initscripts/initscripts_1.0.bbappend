# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://ecm.conf \
           file://dnsmasq.ecm.conf \
           "

do_install_append() {
    install -D -m 0644 ${WORKDIR}/ecm.conf ${D}${sysconfdir}/legato/ecm.conf
    install -D -m 0644 ${WORKDIR}/dnsmasq.ecm.conf ${D}${sysconfdir}/dnsmasq.d/dnsmasq.ecm.conf
}

