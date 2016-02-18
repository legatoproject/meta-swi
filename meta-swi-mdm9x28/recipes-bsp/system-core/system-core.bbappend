
# Tag LE.BR.1.2.1-64400-9x07
SRCREV = "6ba4d991ead9291ab151a60515304405d30724e5"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

DEPENDS += "zlib openssl"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Fix-build-without-liblog.patch"
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
