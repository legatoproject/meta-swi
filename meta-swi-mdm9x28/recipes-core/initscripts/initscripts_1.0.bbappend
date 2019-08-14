do_install_append() {

    ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
}
