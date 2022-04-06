inherit autotools-brokensep module update-rc.d

DESCRIPTION = "Embms Kernel Module"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

PR = "r0"

FILESPATH =+ "${LINUX_REPO_DIR}/net:"

SRC_URI = "file://embms_kernel \
           file://start_embms_le"

S = "${WORKDIR}/embms_kernel"

FILES:${PN} = "${sysconfdir}/"

INITSCRIPT_NAME = "start_embms_le"
INITSCRIPT_PARAMS = "start 35 5 . stop 15 0 1 6 ."

do_install() {
    module_do_install
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/start_embms_le ${D}${sysconfdir}/init.d
}

