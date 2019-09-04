FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://rs485.py \
           "

do_install_append() {
    install -m 0755 ${WORKDIR}/rs485.py -D ${D}/usr/bin/rs485.py

    echo "/usr/sbin/loginNagger" >> ${D}${sysconfdir}/shells
}
