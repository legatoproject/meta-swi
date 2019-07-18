FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "\
            file://mount-copybind \
            file://volatile-binds.service.in \
           "

do_compile_append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        for service in ${@volatile_systemd_services(d)}
        do
            #systemrw-data.service should be started prior than
            #other systemrw-data-*.service.
            case $service in
                systemrw-data-*.service)
                    sed -i -e "/^After=/s/\$/ systemrw-data.service/" $service
                    ;;
                *)
                    ;;
            esac
        done
    fi
}
