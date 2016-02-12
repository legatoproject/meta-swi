DESCRIPTION = "Rebooter daemon"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=3775480a712fc46a69647678acb234cb"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/le/mdm/reboot-daemon/"

PR = "r0"

# Tag LNX.LE.2.0.2-61193-9x15
SRCREV = "d04220ee2b1b46e19369137117bf82cd92e5420a"
REBOOTD_REPO = "git://codeaurora.org/quic/le/mdm/reboot-daemon;branch=rhea"

SRC_URI = "${REBOOTD_REPO}"

inherit autotools

S = "${WORKDIR}/git"

EXTRA_OEMAKE_append = " CROSS=${HOST_PREFIX}"

do_install() {
    install -m 0755 ${S}/../build/reboot-daemon -D ${D}/sbin/reboot-daemon
}
