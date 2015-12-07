inherit module autotools

DESCRIPTION = "Qualcomm Atheros Gigabit Ethernet Driver"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

do_unpack[deptask] = "do_populate_sysroot"
PR = "r3-${KERNEL_VERSION}"

# Tag LNX.LE.5.1-66218-9x40
SRCREV = "abd3d4f028fae12ac8d9e90fb19b84694e228a31"
COMPATWIRELESS_REPO = "git://codeaurora.org/platform/external/compat-wireless;branch=LNX.LE.5.1_rb1.6"

SRC_URI  = "${COMPATWIRELESS_REPO}"
SRC_URI += "file://start_alx_le"

S = "${WORKDIR}/git/drivers/net/ethernet/atheros/alx"
B = "${S}"

FILES_${PN} = "${sysconfdir}/"

inherit update-rc.d

INITSCRIPT_NAME = "start_alx_le"
INITSCRIPT_PARAMS = "start 91 2 3 4 5 . stop 15 0 1 6 ."

do_install() {
    module_do_install

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/start_alx_le ${D}${sysconfdir}/init.d
}
