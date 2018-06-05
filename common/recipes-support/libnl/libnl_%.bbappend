do_install_append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/genl-ctrl-list ${D}/sbin
    ln -s ${sbindir}/nl-class-add ${D}/sbin
    ln -s ${sbindir}/nl-class-delete ${D}/sbin
    ln -s ${sbindir}/nl-classid-lookup ${D}/sbin
    ln -s ${sbindir}/nl-class-list ${D}/sbin
    ln -s ${sbindir}/nl-cls-add ${D}/sbin
    ln -s ${sbindir}/nl-cls-delete ${D}/sbin
    ln -s ${sbindir}/nl-cls-list ${D}/sbin
    ln -s ${sbindir}/nl-link-list ${D}/sbin
    ln -s ${sbindir}/nl-pktloc-lookup ${D}/sbin
    ln -s ${sbindir}/nl-qdisc-add ${D}/sbin
    ln -s ${sbindir}/nl-qdisc-delete ${D}/sbin
    ln -s ${sbindir}/nl-qdisc-list ${D}/sbin
}

FILES_${PN} += " /sbin"
