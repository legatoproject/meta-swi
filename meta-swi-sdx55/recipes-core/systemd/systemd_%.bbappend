FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " file://systemd-tmpfiles-setup.service"
SRC_URI_append += " file://0001-systemctl-restore-systemctl-reboot-ARG-functionality.patch"

do_install_append () {
    #don't Mask journaling services by default.
    rm -f ${D}/etc/systemd/system/systemd-journald.service
    rm -f ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-flush.service
    rm -f ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-catalog-update.service

    install -m 0644 ${WORKDIR}/systemd-tmpfiles-setup.service ${D}/lib/systemd/system/
}
