DESCRIPTION = "Sierra Wireless Legato Initialization"
HOMEPAGE = "http://www.sierrawireless.com"
LICENSE = "SierraWireless-Proprietary"
LIC_FILES_CHKSUM = "file://../startlegato.sh;startline=2;endline=2;md5=3a6143426a9c75229175e743950f0ddc"

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

do_install_append () {
    install -m 0755 ${WORKDIR}/startlegato.sh -D ${D}${sysconfdir}/init.d/startlegato.sh

    [ -n "${D}" ] && OPT="-r ${D}" || OPT="-s"
    update-rc.d $OPT -f startlegato.sh remove
    update-rc.d $OPT startlegato.sh start 99 S . stop 01 S .
}

FILES_${PN} = " \
          ${sysconfdir}/ \
              "
