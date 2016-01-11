# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://modules \
           "

do_install_append() {
    install -m 0644 ${WORKDIR}/modules ${D}${sysconfdir}/modules
}
