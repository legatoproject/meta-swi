# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://etc/group \
           file://etc/gshadow \
           file://etc/passwd \
           file://etc/shadow \
           file://etc/dropbear/dropbear_rsa_host_key \
           "

do_install_append() {
    install -D -m 0664 ${WORKDIR}/etc/group -D ${D}${sysconfdir}/group
    install -D -m 0400 ${WORKDIR}/etc/gshadow -D ${D}${sysconfdir}/gshadow
    install -D -m 0664 ${WORKDIR}/etc/passwd -D ${D}${sysconfdir}/passwd
    install -D -m 0400 ${WORKDIR}/etc/shadow -D ${D}${sysconfdir}/shadow
    install -D -m 0644 ${WORKDIR}/etc/dropbear/dropbear_rsa_host_key ${D}${sysconfdir}/dropbear/dropbear_rsa_host_key

    ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
}

