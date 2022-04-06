PACKAGECONFIG:remove = "gnutls"
DEPENDS:remove = "gnutls"

DEPENDS += "openssl"

FILESEXTRAPATHS:prepend := "${THISDIR}/wpa-supplicant:"

SRC_URI += " \
            file://0001-wpa-supplicant-MT7697-support.patch \
           "

do_install:append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/wpa_supplicant ${D}/sbin/
    ln -s ${sbindir}/wpa_cli ${D}/sbin/
    ln -s ${bindir}/wpa_passphrase ${D}/sbin/
}

FILES:${PN} += " /sbin"
