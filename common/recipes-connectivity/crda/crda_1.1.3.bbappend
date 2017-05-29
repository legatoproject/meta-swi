do_install_append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/crda ${D}/sbin
}

RDEPENDS_${PN} = ""
FILES_${PN} += " /sbin"
