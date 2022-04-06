FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_install() {
    # Do not append getty dynamically as run_getty.sh will take care
    # of starting it.
    install -d ${D}${sysconfdir}
    install -D -m 0644 ${WORKDIR}/inittab ${D}${sysconfdir}/inittab
}
