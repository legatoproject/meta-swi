
# Tag LE.BR.1.2.1-59300-9x07
SRCREV = "dd72ed8c45bb873f7159a94fb30269b6f1a216af"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

DEPENDS += "zlib openssl libcap"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://composition-sierra_dev"
SRC_URI += "file://start_usb"
SRC_URI += "file://0001-Fix-adbd-crash-issue.patch"

do_install_append() {
    install -m 0755 ${WORKDIR}/composition-sierra_dev -D ${D}${bindir}/usb/compositions/sierra_dev
    ln -s ${bindir}/usb/compositions/sierra_dev ${D}${bindir}/usb/boot_hsusb_composition
    ln -s ${bindir}/usb/compositions/empty      ${D}${bindir}/usb/boot_hsic_composition

    # Simpler usb start-up script than the one provided on CodeAurora
    install -m 0755 ${WORKDIR}/start_usb -D ${D}${sysconfdir}/init.d/usb
}

EXTRA_OEMAKE = "INCLUDES='-I${S}/include -I${S}/fastboot -I${S}/mkbootimg'"
