DESCRIPTION = "Rebooter daemon"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=3775480a712fc46a69647678acb234cb"

PR = "r0"

SRC_URI = "git://codeaurora.org/quic/le/mdm/reboot-daemon;rev=d04220ee2b1b46e19369137117bf82cd92e5420a"

inherit autotools

S = "${WORKDIR}/git"

EXTRA_OEMAKE_append = " CROSS=${HOST_PREFIX}"

do_install() {
    install -m 0755 ${S}/reboot-daemon -D ${D}/sbin/reboot-daemon
}
