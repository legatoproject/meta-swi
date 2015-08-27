DESCRIPTION = "Rebooter daemon"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=3775480a712fc46a69647678acb234cb"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/le/mdm/reboot-daemon/"

PR = "r0"

# Tag M9615AAAARNLZA1713041
SRCREV = "a88717ab8a5ae77f5358b9af539ccf0574acc70c"
SRC_URI = "git://codeaurora.org/quic/le/mdm/reboot-daemon"

inherit autotools

S = "${WORKDIR}/git"

EXTRA_OEMAKE_append = " CROSS=${HOST_PREFIX}"

do_install() {
    install -m 0755 ${S}/../build/reboot-daemon -D ${D}/sbin/reboot-daemon
}
