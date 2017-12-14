# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://load_modem.sh \
           file://etc/group \
           file://etc/gshadow \
           file://etc/passwd \
           file://etc/shadow \
           "

do_install_append() {

    # if it is RAM image, don't need to load modem
    if [ "${MACHINE}" != "swi-mdm9x40-ar759x-rcy" ]; then
        install -D -m 0755 ${WORKDIR}/load_modem.sh -D ${D}${sysconfdir}/init.d/load_modem.sh
        update-rc.d $OPT load_modem.sh start 09 S . stop 90 S .
    fi

    install -D -m 0664 ${WORKDIR}/etc/group -D ${D}${sysconfdir}/group
    install -D -m 0400 ${WORKDIR}/etc/gshadow -D ${D}${sysconfdir}/gshadow
    install -D -m 0664 ${WORKDIR}/etc/passwd -D ${D}${sysconfdir}/passwd
    install -D -m 0400 ${WORKDIR}/etc/shadow -D ${D}${sysconfdir}/shadow

    ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
}
