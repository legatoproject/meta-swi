inherit update-alternatives

do_install_append() {
    for x in i2cget i2cset i2cdump i2cdetect; do
        mv ${D}${sbindir}/$x ${D}${sbindir}/$x.${BPN}
    done
}

ALTERNATIVE_PRIORITY = "100"
ALTERNATIVE_${PN} = "i2cget i2cset i2cdump i2cdetect"

ALTERNATIVE_LINK_NAME[i2cget] = "${sbindir}/i2cget"
ALTERNATIVE_TARGET[i2cget] = "${sbindir}/i2cget.${BPN}"

ALTERNATIVE_LINK_NAME[i2cset] = "${sbindir}/i2cset"
ALTERNATIVE_TARGET[i2cset] = "${sbindir}/i2cset.${BPN}"

ALTERNATIVE_LINK_NAME[i2cdump] = "${sbindir}/i2cdump"
ALTERNATIVE_TARGET[i2cdump] = "${sbindir}/i2cdump.${BPN}"

ALTERNATIVE_LINK_NAME[i2cdetect] = "${sbindir}/i2cdetect"
ALTERNATIVE_TARGET[i2cdetect] = "${sbindir}/i2cdetect.${BPN}"
