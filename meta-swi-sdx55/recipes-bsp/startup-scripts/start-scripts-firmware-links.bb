DESCRIPTION = "Start up script for firmware links"
HOMEPAGE = "http://codeaurora.org"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"

SRC_URI +="file://firmware-links.sh"
SRC_URI +="file://firmware-links.service"

S = "${WORKDIR}"

PR = "r5"

inherit systemd

do_install() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'ro-rootfs', 'false', 'true', d)}; then
        if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
           install -m 0755 ${WORKDIR}/${BASEMACHINE}/firmware-links.sh -D ${D}${sysconfdir}/initscripts/firmware-links.sh
           install -d ${D}${systemd_unitdir}/system/
           install -m 0644 ${WORKDIR}/firmware-links.service -D ${D}${systemd_unitdir}/system/firmware-links.service
           install -d ${D}${systemd_unitdir}/system/sysinit.target.wants/
           # enable the service for sysinit.target
           ln -sf ${systemd_unitdir}/system/firmware-links.service \
                ${D}${systemd_unitdir}/system/sysinit.target.wants/firmware-links.service
        else
           install -m 0755 ${WORKDIR}/${BASEMACHINE}/firmware-links.sh -D ${D}${sysconfdir}/init.d/firmware-links.sh
        fi
    fi
}

# Beyond msm-3.18 /lib/firmware/image is no longer a valid PIL search path.
# Use /lib/firmware/updates instead till userspace is capable of firmware load.
do_install_append() {
    install -d ${D}/firmware
    install -d ${D}/lib/firmware
    if ${@oe.utils.version_less_or_equal('PREFERRED_VERSION_linux-msm', '3.18', 'true', 'false', d)}; then
        ln -s /firmware/image ${D}/lib/firmware/image
    else
        ln -s /firmware/image ${D}/lib/firmware/updates
    fi
}

FILES_${PN} += "/lib/* /firmware"
FILES_${PN} += "${systemd_unitdir}/system/"
