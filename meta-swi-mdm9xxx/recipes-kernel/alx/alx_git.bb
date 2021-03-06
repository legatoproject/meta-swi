inherit module autotools

DESCRIPTION = "Qualcomm Atheros Gigabit Ethernet Driver"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

do_unpack[deptask] = "do_populate_sysroot"
PR = "r3"

# Tag LNX.LE.5.1-66218-9x40
SRCREV = "abd3d4f028fae12ac8d9e90fb19b84694e228a31"
COMPATWIRELESS_REPO = "git://codeaurora.org/platform/external/compat-wireless;branch=LNX.LE.5.1_rb1.10"

SRC_URI  = "${COMPATWIRELESS_REPO}"
SRC_URI += "file://start_alx_le"
SRC_URI += "file://0001-Module-cannot-deep-sleep.patch;striplevel=6"

S = "${WORKDIR}/git/drivers/net/ethernet/atheros/alx"
B = "${S}"

FILES_${PN} = "${sysconfdir}/"

inherit update-rc.d

INITSCRIPT_NAME = "start_alx_le"
INITSCRIPT_PARAMS = "start 91 S . stop 15 S ."

do_install() {
    module_do_install

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/start_alx_le ${D}${sysconfdir}/init.d
}

