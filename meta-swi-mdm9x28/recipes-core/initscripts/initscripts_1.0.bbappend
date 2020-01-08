# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
           file://run.env \
           "

do_install_append() {
    rm -f ${D}${sysconfdir}/run.env
    # Common functions and environment
    install -m 0444 ${WORKDIR}/functions.env -D ${D}${sysconfdir}/run.env
    # Append custom environment from platform-specific layer
    cat ${WORKDIR}/run.env >> "${D}${sysconfdir}/run.env"
    if [ "x${IMA_BUILD}" == "xtrue" ] ; then
        # remove the empty resolv.conf file created at the common layer, then
        # create a soft link. the actual writeable file (/var/resolv.conf) will
        # be created in mount-early.in
        rm -f ${D}${sysconfdir}/resolv.conf
        ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
    fi
}
