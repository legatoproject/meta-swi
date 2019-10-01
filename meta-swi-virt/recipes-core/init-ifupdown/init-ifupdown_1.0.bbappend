# Look at this directory first.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://private-routes \
           "

do_install_append() {
    install -d ${D}${sysconfdir}/network/if-up.d
    install -m 0755 ${WORKDIR}/private-routes -D ${D}${sysconfdir}/network/if-up.d/
}
