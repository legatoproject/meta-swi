do_install_append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/wpa_supplicant ${D}/sbin/
    ln -s ${sbindir}/wpa_cli ${D}/sbin/
    ln -s ${bindir}/wpa_passphrase ${D}/sbin/
}

FILES_${PN} += " /sbin"
