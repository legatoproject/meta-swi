# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://restartNMEA \
           "
do_install_append() {
    # Replace the generic mdm9xxx restartNMEA with an mdm9x15 variant
    install -m 0755 ${WORKDIR}/restartNMEA -D ${D}${sbindir}/restartNMEA
}
