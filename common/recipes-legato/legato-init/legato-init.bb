DESCRIPTION = "Sierra Wireless Legato Initialization"
HOMEPAGE = "http://www.sierrawireless.com"
LICENSE = "SierraWireless-Proprietary"
LIC_FILES_CHKSUM = "file://../startlegato.sh;startline=2;endline=2;md5=0357211a003ec058e91c7f12c9922033"

SRC_URI = " \
          file://startlegato.sh \
          file://startlegato-compat.sh \
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
    install -m 0755 ${WORKDIR}/startlegato-compat.sh -D ${D}${sysconfdir}/init.d/startlegato-compat.sh

    [ -n "${D}" ] && OPT="-r ${D}" || OPT="-s"
    update-rc.d $OPT -f startlegato.sh remove
    update-rc.d $OPT startlegato.sh start 44 S . stop 06 S .
}

FILES_${PN} = " \
          ${sysconfdir}/ \
              "
