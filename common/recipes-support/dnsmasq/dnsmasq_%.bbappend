# Look at this directlry first.
FILESEXTRAPATHS_append := "${THISDIR}/files:"

INITSCRIPT_PARAMS = "start 94 S . stop 80 S ."

do_install_prepend() {
    sed -i 's/dhcp-range=10.0.0.10,10.0.0.200,2h//' ${WORKDIR}/dnsmasq.conf
    echo "#interface=wlan0" >> ${WORKDIR}/dnsmasq.conf
}
