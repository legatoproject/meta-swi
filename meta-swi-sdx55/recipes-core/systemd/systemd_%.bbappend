FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " file://systemd-tmpfiles-setup.service"
SRC_URI_append += " file://0001-systemctl-restore-systemctl-reboot-ARG-functionality.patch"

do_install_append () {
    #don't Mask journaling services by default.
    rm -f ${D}/etc/systemd/system/systemd-journald.service
    rm -f ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-flush.service
    rm -f ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-catalog-update.service

    install -m 0644 ${WORKDIR}/systemd-tmpfiles-setup.service ${D}/lib/systemd/system/

    #fixup pcie can't work if loading mhinet driver automaticlly.
    #remove sysinit.target dependency and install it into sockets.target.wants.
    sed -i 's/After=sysinit.target /After=/g' ${D}${systemd_unitdir}/system/systemd-udev-trigger.service
    sed -i '/After=init_sys_mss.service/a Before=sockets.target' ${D}${systemd_unitdir}/system/systemd-udev-trigger.service
    rm -f ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-udev-trigger.service
    ln -sf /lib/systemd/system/systemd-udev-trigger.service \
        ${D}${systemd_unitdir}/system/sockets.target.wants/systemd-udev-trigger.service
}
