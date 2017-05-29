
do_install_append() {
     install -m 0755 -d ${D}/bin
     ln -s ${sbindir}/hostapd ${D}/bin/
     ln -s ${sbindir}/hostapd_cli ${D}/bin/
}
