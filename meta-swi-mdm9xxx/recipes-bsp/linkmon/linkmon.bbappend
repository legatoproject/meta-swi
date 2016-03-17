FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://enable_autosleep.sh"

inherit update-rc.d

INITSCRIPT_NAME = "enable_autosleep.sh"
INITSCRIPT_PARAMS = "start 99 S . stop 01 S ."

do_install_append() {
    install -m 0755 ${WORKDIR}/enable_autosleep.sh -D ${D}${sysconfdir}/init.d/enable_autosleep.sh
}

