# Look at this directory first.
FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
            file://dnsmasq-qca.conf \
           "

INITSCRIPT_PARAMS = "start 94 S . stop 80 S ."

do_install:prepend() {
    sed -i 's/dhcp-range=10.0.0.10,10.0.0.200,2h//' ${WORKDIR}/dnsmasq.conf
    echo "#interface=wlan0" >> ${WORKDIR}/dnsmasq.conf
}

do_install:append() {

    install -m 0644 ${WORKDIR}/dnsmasq-qca.conf -D \
        ${D}/${sysconfdir}/dnsmasq-qca.conf

}
