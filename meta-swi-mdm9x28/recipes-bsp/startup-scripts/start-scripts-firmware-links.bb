DESCRIPTION = "Start up script for firmware links"
HOMEPAGE = "http://codeaurora.org"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/BSD;md5=3775480a712fc46a69647678acb234cb"
LICENSE = "BSD"

SRC_URI +="file://firmware-links.sh"

PR = "r4"

inherit update-rc.d

INITSCRIPT_NAME   = "firmware-links.sh"
INITSCRIPT_PARAMS = "start 37 S ."

do_install() {
    install -m 0755 ${WORKDIR}/firmware-links.sh -D ${D}${sysconfdir}/init.d/firmware-links.sh
}

pkg_postinst_${PN} () {
    update-alternatives --install ${sysconfdir}/init.d/firmware-links.sh firmware-links.sh firmware-links.sh 60
    [ -n "$D" ] && OPT="-r $D" || OPT="-s"
    # remove all rc.d-links potentially created from alternatives
    update-rc.d $OPT -f firmware-links.sh remove
    update-rc.d $OPT firmware-links.sh multiuser
}

