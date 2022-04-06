# Look at this directory first.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://private-routes \
           "

do_install:append() {
    install -d ${D}${sysconfdir}/network/if-up.d
    install -m 0755 ${WORKDIR}/private-routes -D ${D}${sysconfdir}/network/if-up.d/
}
