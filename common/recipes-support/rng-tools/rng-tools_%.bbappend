do_install_append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'false', 'true', d)}; then
        sed -i -e 's,${sbindir},${sbindir}/,' \
            ${D}${sysconfdir}/init.d/rng-tools
    fi
}
