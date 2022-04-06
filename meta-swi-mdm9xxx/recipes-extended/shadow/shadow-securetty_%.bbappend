
#  Allow root to login on the console

do_install:append() {
    echo "" >> ${D}${sysconfdir}/securetty
    echo "# High speed serial ports (used as console)" >> ${D}${sysconfdir}/securetty
    echo "ttyHS0" >> ${D}${sysconfdir}/securetty
    echo "ttyMSM0" >> ${D}${sysconfdir}/securetty
    echo "ttyMSM1" >> ${D}${sysconfdir}/securetty
    echo "ttyHSL0" >> ${D}${sysconfdir}/securetty
    echo "ttyHSL1" >> ${D}${sysconfdir}/securetty
}

