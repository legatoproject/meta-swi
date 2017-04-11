
do_install_append() {
    sed -i -e 's,${sbindir},${sbindir}/,' \
        ${D}${sysconfdir}/init.d/rng-tools
}
