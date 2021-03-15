FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://0001-ALPC-232-Provide-factory-default-recovery-mechanism.patch \
           "

do_install_append() {
    rm -f ${D}${sysconfdir}/run.env
    # Common functions and environment
    install -m 0444 ${WORKDIR}/functions.env -D ${D}${sysconfdir}/run.env
    # Append custom environment from platform-specific layer
    cat ${WORKDIR}/run.env >> ${D}${sysconfdir}/run.env
}
