DESCRIPTION = "Legato Initialization"
HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://../startlegato.sh;startline=2;endline=2;md5=3c2fa32f2c886dd9f19dad1b05ed1ced"

SRC_URI = " \
          file://startlegato.sh \
          "

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

do_configure() {
    :
}

do_compile() {
    :
}

INITSCRIPT_NAME = "startlegato.sh"
INITSCRIPT_PARAMS = "start 44 S . stop 06 S ."

inherit update-rc.d

do_install_append () {
    install -m 0755 ${WORKDIR}/startlegato.sh -D ${D}${sysconfdir}/init.d/startlegato.sh
}

FILES_${PN} = " \
          ${sysconfdir}/ \
              "
