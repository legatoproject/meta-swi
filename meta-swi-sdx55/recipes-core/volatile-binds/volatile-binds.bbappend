FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

#override mount-copybind in recipes-bsp/volatile-binds,
#as mount overlay is much faster than copying files.
#the mount-copybind is copied from poky/meta/recipes-core/volatile-binds/files/mount-copybind
#of warrior.
SRC_URI += "\
            file://mount-copybind \
            file://volatile-binds.service.in \
           "

VOLATILE_BINDS = "\
/tmp/systemrw/adb_devid  /etc/adb_devid\n\
/tmp/systemrw/build.prop /etc/build.prop\n\
/tmp/systemrw/data /etc/data/\n\
/tmp/systemrw/data/adpl /etc/data/adpl/\n\
/tmp/systemrw/data/usb /etc/data/usb/\n\
/tmp/systemrw/data/miniupnpd /etc/data/miniupnpd/\n\
/tmp/systemrw/data/ipa /etc/data/ipa/\n\
/tmp/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/tmp/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/tmp/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
/tmp/systemrw/misc/wifi /etc/misc/wifi/\n\
/tmp/systemrw/bluetooth /etc/bluetooth/\n\
/tmp/systemrw/allplay /etc/allplay/\n\
"

do_compile_append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        for service in ${@volatile_systemd_services(d)}
        do
            #tmp-systemrw-data.service should be started prior than
            #other tmp-systemrw-data-*.service.
            case $service in
                tmp-systemrw-data-*.service)
                    sed -i -e "/^After=/s/\$/ tmp-systemrw-data.service/" $service
                    ;;
                *)
                    ;;
            esac
        done
    fi
}

do_install_append() {
    #umount-copybind from bsp is unusable
    rm -f ${D}${base_sbindir}/umount-copybind
}
