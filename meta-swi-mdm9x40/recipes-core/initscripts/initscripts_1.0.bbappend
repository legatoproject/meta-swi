# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://etc/group \
           file://etc/gshadow \
           file://etc/passwd \
           file://etc/shadow \
           file://start_eth_modules_le \
           file://swi_mount_qct_cfg_file \
           file://ecm.conf \
           file://dnsmasq.ecm.conf \
           "

do_install_append() {

    # if it is RAM image, don't need to load modem
    if [ "${MACHINE}" != "swi-mdm9x40-ar759x-rcy" ]; then
        install -D -m 0755 ${WORKDIR}/start_eth_modules_le -D ${D}${sysconfdir}/init.d/start_eth_modules_le
        install -D -m 0755 ${WORKDIR}/swi_mount_qct_cfg_file -D ${D}${sysconfdir}/init.d/swi_mount_qct_cfg_file
        update-rc.d $OPT swi_mount_qct_cfg_file start 36 S .
        update-rc.d $OPT start_eth_modules_le start 26 S .
    fi

    install -D -m 0664 ${WORKDIR}/etc/group -D ${D}${sysconfdir}/group
    install -D -m 0400 ${WORKDIR}/etc/gshadow -D ${D}${sysconfdir}/gshadow
    install -D -m 0664 ${WORKDIR}/etc/passwd -D ${D}${sysconfdir}/passwd
    install -D -m 0400 ${WORKDIR}/etc/shadow -D ${D}${sysconfdir}/shadow

    install -D -m 0644 ${WORKDIR}/ecm.conf ${D}${sysconfdir}/legato/ecm.conf
    install -D -m 0644 ${WORKDIR}/dnsmasq.ecm.conf ${D}${sysconfdir}/dnsmasq.d/dnsmasq.ecm.conf

    ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
}
