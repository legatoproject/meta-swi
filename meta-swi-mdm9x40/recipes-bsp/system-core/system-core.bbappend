
# Tag LNX.LE.5.3-79003-9x40
SRCREV = "75510472603f316d045c917a799ec4b7562ff1f0"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=LNX.LE.5.3_rb1.2"

DEPENDS += "zlib openssl libcap"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-typo-in-configure-ac.patch"
SRC_URI += "file://composition-sierra_dev"
SRC_URI += "file://start_usb"

do_install_append() {
    install -m 0755 ${WORKDIR}/composition-sierra_dev -D ${D}${bindir}/usb/compositions/sierra_dev
    ln -s ${bindir}/usb/compositions/sierra_dev ${D}${bindir}/usb/boot_hsusb_composition
    ln -s ${bindir}/usb/compositions/empty      ${D}${bindir}/usb/boot_hsic_composition

    # Simpler usb start-up script than the one provided on CodeAurora
    install -m 0755 ${WORKDIR}/start_usb -D ${D}${sysconfdir}/init.d/usb
}

EXTRA_OEMAKE = "INCLUDES='-I${S}/include -I${S}/fastboot -I${S}/mkbootimg'"
