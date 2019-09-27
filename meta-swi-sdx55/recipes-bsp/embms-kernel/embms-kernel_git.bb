inherit autotools-brokensep module update-rc.d

DESCRIPTION = "Embms Kernel Module"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

PR = "${@oe.utils.conditional('PRODUCT', 'psm', 'r0-psm', 'r0', d)}"

FILESPATH =+ "${WORKSPACE}:"

SRC_URI = "${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '4.14', 'file://kernel/msm-4.14/net/embms_kernel/', '', d)} \
           ${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '4.9', 'file://kernel/msm-4.9/net/embms_kernel/', '', d)} \
           ${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '3.18', 'file://kernel/msm-3.18/net/embms_kernel/', '', d)} \
           file://start_embms_le \
           file://embmsd.service"

S = "${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '4.14', '${WORKDIR}/kernel/msm-4.14/net/embms_kernel/', '', d)} \
     ${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '4.9', '${WORKDIR}/kernel/msm-4.9/net/embms_kernel/', '', d)} \
     ${@oe.utils.conditional('PREFERRED_VERSION_linux-msm', '3.18', '${WORKDIR}/kernel/msm-3.18/net/embms_kernel/', '', d)}"

FILES_${PN}="/etc/init.d/start_embms_le"
FILES_${PN}+="/etc/initscripts/start_embms_le"
FILES_${PN}+= "${systemd_unitdir}/system/embmsd.service"
FILES_${PN}+= "${systemd_unitdir}/system/multi-user.target.wants/embmsd.service"

do_install() {
    module_do_install
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/start_embms_le ${D}${sysconfdir}/init.d
}

INITSCRIPT_NAME = "start_embms_le"
INITSCRIPT_PARAMS = "start 35 5 . stop 15 0 1 6 ."

do_install_append_mdm() {
        if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
              install -d ${D}${systemd_unitdir}/system/
              #embms-kernel service
              rm -rf ${D}${sysconfdir}/init.d/start_embms_le
              install -d ${D}${sysconfdir}/initscripts
              install -m 0755 ${WORKDIR}/start_embms_le ${D}${sysconfdir}/initscripts
              install -m 0644 ${WORKDIR}/embmsd.service -D ${D}${systemd_unitdir}/system/embmsd.service
              install -d ${D}${systemd_unitdir}/system/multi-user.target.wants/
              # enable the service for multi-user.target
              ln -sf ${systemd_unitdir}/system/embmsd.service \
              ${D}${systemd_unitdir}/system/multi-user.target.wants/embmsd.service
        fi
}