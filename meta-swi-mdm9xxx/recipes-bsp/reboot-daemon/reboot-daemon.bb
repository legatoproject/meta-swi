DESCRIPTION = "Rebooter daemon"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/le/mdm/reboot-daemon/"

PR = "r0"

# Tag LNX.LE.2.0.2-61193-9x15
SRCREV = "d04220ee2b1b46e19369137117bf82cd92e5420a"
REBOOTD_REPO = "git://codeaurora.org/quic/le/mdm/reboot-daemon;branch=rhea"

SRC_URI = "${REBOOTD_REPO}"

inherit autotools

S = "${WORKDIR}/git"

EXTRA_OEMAKE:append = " CROSS=${HOST_PREFIX}"

do_install() {
    install -m 0755 ${S}/../build/reboot-daemon -D ${D}/sbin/reboot-daemon
}
