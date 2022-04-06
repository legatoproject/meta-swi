do_install:append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/crda ${D}/sbin
}

RDEPENDS:${PN} = ""
FILES:${PN} += " /sbin"
