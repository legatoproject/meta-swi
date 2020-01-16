do_install_append() {
    if [ "x${IMA_BUILD}" == "xtrue" ] ; then
        # remove the empty resolv.conf file created at the common layer, then
        # create a soft link. the actual writeable file (/var/resolv.conf) will
        # be created in mount-early.in
        rm -f ${D}${sysconfdir}/resolv.conf
        ln -s /var/resolv.conf ${D}${sysconfdir}/resolv.conf
    fi
}
