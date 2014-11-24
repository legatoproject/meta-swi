# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://init"

INITSCRIPT_PARAMS_dropbear = "start 10 2 3 4 5 . stop 10 0 1 6 ."

do_install_append () {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/dropbear
}
