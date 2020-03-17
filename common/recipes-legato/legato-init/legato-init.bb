DESCRIPTION = "Legato Initialization"
HOMEPAGE = "https://legato.io/"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MPL-2.0;md5=815ca599c9df247a0c7f619bab123dad"

SRC_URI = "file://startlegato.sh"

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
