FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://hostapd-part-qca.conf \
           "

do_install_append() {
    install -m 0755 -d ${D}/bin
    ln -s ${sbindir}/hostapd ${D}/bin/
    ln -s ${sbindir}/hostapd_cli ${D}/bin/

    install -m 0644 ${WORKDIR}/hostapd-part-qca.conf -D \
        ${D}/${sysconfdir}/hostapd-part-qca.conf
}
