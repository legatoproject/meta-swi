# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

do_install_append() {
    echo "/usr/sbin/loginNagger" >> ${D}${sysconfdir}/shells
}
