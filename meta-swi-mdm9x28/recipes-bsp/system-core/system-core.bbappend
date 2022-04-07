
# Tag LE.BR.1.2.1-44100-9x07
SRCREV = "95852f8b85a9b2d190b395aaf9621fb6cca90dc6"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=mdm"

DEPENDS += "zlib openssl libcap"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:swi-mdm9x28 = " file://0001-Fix-build-without-liblog.patch"
SRC_URI += "file://composition-sierra_dev"
SRC_URI += "file://start_usb"
SRC_URI += "file://0002-QTI9X07-125-Do-not-start-adb-if-not-enabled.patch"
SRC_URI += "file://0001-Fix-adbd-crash-issue.patch"
SRC_URI += "file://fix-big-endian-build.patch"
SRC_URI += "file://use-accessors-for-rsa.patch"
SRC_URI += "file://include-sysmacros-for-major.patch"
SRC_URI += "file://0001-logging-Add-Android-logging-macros.patch"

do_install:append() {
    install -m 0755 -d ${D}${includedir}/log
    install -m 0644  ${S}/include/log/* ${D}${includedir}/log
    rm ${D}${bindir}/usb_composition
    rm ${D}${bindir}/usb/compositions/*
    install -m 0755 ${S}/usb/compositions/empty -D ${D}${bindir}/usb/compositions/empty
    install -m 0755 ${WORKDIR}/composition-sierra_dev -D ${D}${bindir}/usb/compositions/sierra_dev
    ln -s ${bindir}/usb/compositions/sierra_dev ${D}${bindir}/usb/boot_hsusb_composition
    ln -s ${bindir}/usb/compositions/empty      ${D}${bindir}/usb/boot_hsic_composition

    # Simpler usb start-up script than the one provided on CodeAurora
    install -m 0755 ${WORKDIR}/start_usb -D ${D}${sysconfdir}/init.d/usb
}

EXTRA_OEMAKE = "INCLUDES='-I${S}/include -I${S}/fastboot -I${S}/mkbootimg'"
