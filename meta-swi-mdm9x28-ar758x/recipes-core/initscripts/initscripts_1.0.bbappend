# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://etc/dropbear/dropbear_rsa_host_key \
           "

do_install_append() {
    install -D -m 0644 ${WORKDIR}/etc/dropbear/dropbear_rsa_host_key ${D}${sysconfdir}/dropbear/dropbear_rsa_host_key

    ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
}

