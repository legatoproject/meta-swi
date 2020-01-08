# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://etc/dropbear/dropbear_rsa_host_key \
           file://run.env \
           "

do_install_append() {
    rm -f ${D}${sysconfdir}/run.env
    # Common functions and environment
    install -m 0444 ${WORKDIR}/functions.env -D ${D}${sysconfdir}/run.env
    # Append custom environment from platform-specific layer
    cat ${WORKDIR}/run.env >> ${D}${sysconfdir}/run.env
    install -D -m 0644 ${WORKDIR}/etc/dropbear/dropbear_rsa_host_key ${D}${sysconfdir}/dropbear/dropbear_rsa_host_key
}

