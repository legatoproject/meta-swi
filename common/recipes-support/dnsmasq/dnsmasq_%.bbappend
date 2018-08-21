# Look at this directory first.
FILESEXTRAPATHS_append := "${THISDIR}/files:"

SRC_URI += " \
            file://dnsmasq-qca.conf \
           "

INITSCRIPT_PARAMS = "start 94 S . stop 80 S ."

do_install_prepend() {
    sed -i 's/dhcp-range=10.0.0.10,10.0.0.200,2h//' ${WORKDIR}/dnsmasq.conf
    echo "#interface=wlan0" >> ${WORKDIR}/dnsmasq.conf
}

do_install_append() {

    if [ "x${ENABLE_QCA9377}" = "x1" ] ; then
        install -m 0644 ${WORKDIR}/dnsmasq-qca.conf -D \
            ${D}/${sysconfdir}/dnsmasq-qca.conf
    fi

}
