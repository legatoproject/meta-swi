DESCRIPTION = "Start up script for firmware links"
HOMEPAGE = "http://codeaurora.org"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/BSD;md5=3775480a712fc46a69647678acb234cb"
LICENSE = "BSD"

SRC_URI +="file://firmware-links.sh"

PR = "r4"

FILES_${PN} += "/lib/firmware/*"

do_install() {
    install -d ${D}/lib/firmware
    ln -s /firmware/image ${D}/lib/firmware/image
    install -m 0755 ${WORKDIR}/firmware-links.sh -D ${D}${sysconfdir}/init.d/firmware-links.sh
}

