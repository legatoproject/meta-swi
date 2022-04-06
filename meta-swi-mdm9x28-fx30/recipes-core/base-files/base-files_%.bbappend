FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://rs485.py \
            file://nagger \
           "

do_install:append() {
    install -m 0755 ${WORKDIR}/rs485.py -D ${D}/usr/bin/rs485.py

    install -m 0755 ${WORKDIR}/nagger -D ${D}${sysconfdir}/nagger
    echo "/etc/nagger" >> ${D}${sysconfdir}/shells
}
