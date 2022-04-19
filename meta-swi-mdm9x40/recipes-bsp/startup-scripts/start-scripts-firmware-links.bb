DESCRIPTION = "Start up script for firmware links"
HOMEPAGE = "http://codeaurora.org"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI ="file://firmware-links.sh"

PR = "r4"

FILES_${PN} += "/lib/firmware/*"

do_install() {
    install -d ${D}/lib/firmware
    ln -s /firmware/image ${D}/lib/firmware/image
    install -m 0755 ${WORKDIR}/firmware-links.sh -D ${D}${sysconfdir}/init.d/firmware-links.sh
}

