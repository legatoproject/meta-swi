# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

ECM_INTERFACE ?= "usb0"

SRC_URI_append = "\
           file://restartNMEA \
           file://run.env \
           "

do_install_append() {
    rm -f ${D}${sysconfdir}/run.env
    # Common functions and environment
    install -m 0444 ${WORKDIR}/functions.env -D ${D}${sysconfdir}/run.env
    # Append custom environment from platform-specific layer
    cat ${WORKDIR}/run.env >> ${D}${sysconfdir}/run.env
    # Replace the generic mdm9xxx restartNMEA with an mdm9x15 variant
    install -m 0755 ${WORKDIR}/restartNMEA -D ${D}${sbindir}/restartNMEA
}
