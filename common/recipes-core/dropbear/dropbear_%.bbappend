FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://init.wrapper"

INITSCRIPT_NAME = "dropbear.wrapper"
INITSCRIPT_PARAMS = "start 95 S . stop 90 S ."

do_install:append() {
    install -m 0755 ${WORKDIR}/init.wrapper ${D}${sysconfdir}/init.d/dropbear.wrapper
}
