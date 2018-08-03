FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://defconfig_qca9377 \
            file://hostapd-qca.conf \
           "

do_configure_append() {
    # DM: For now, do this conditional. However, the fact is that new config
    # file contains only configuration additions, and we should not have
    # any problems replacing old config file with new one.
    if [ "x${ENABLE_QCA9377}" = "x1" ] ; then
        install -m 0644 ${WORKDIR}/defconfig_qca9377 ${B}/.config
    fi
}

do_install_append() {
    install -m 0755 -d ${D}/bin
    ln -s ${sbindir}/hostapd ${D}/bin/
    ln -s ${sbindir}/hostapd_cli ${D}/bin/

    if [ "x${ENABLE_QCA9377}" = "x1" ] ; then
        install -m 0644 ${WORKDIR}/hostapd-qca.conf -D \
	    ${D}/${sysconfdir}/hostapd.conf
    fi
}
