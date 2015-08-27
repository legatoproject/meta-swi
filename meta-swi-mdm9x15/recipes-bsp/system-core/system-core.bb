DESCRIPTION = "Android system/core components"
HOMEPAGE = "https://www.codeaurora.org/cgit/external/gigabyte/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

PR = "r1"

# Tag M9615AAAARNLZA1611263
SRCREV = "7b371cbcfc38e1485f31f8e3087a6a33211e7da2"
SRC_URI = "git://codeaurora.org/platform/system/core;branch=penguin \
           file://50-log.rules \
           file://composition-sierra \
           file://0001-Fix-libmincrypt-include-path.patch \
           "

inherit autotools

S = "${WORKDIR}/git"

ALLOW_EMPTY_${PN} = "1"

INITSCRIPT_PACKAGES = "${PN}-adbd ${PN}-usb"

INITSCRIPT_NAME_${PN}-adbd = "adbd"
INITSCRIPT_PARAMS_${PN}-adbd = "start 96 S . stop 58 S ."
INITSCRIPT_NAME_${PN}-usb = "usb"
INITSCRIPT_PARAMS_${PN}-usb = "start 09 S ."

inherit update-rc.d

EXTRA_OEMAKE = "INCLUDES='-I${S}/include'"

do_install_append() {
   install -m 0755 -d ${D}${includedir}/cutils
   install -m 0644  ${S}/include/cutils/* ${D}${includedir}/cutils
   install -m 0644 -D ${S}/include/android/log.h ${D}${includedir}/android/log.h
   install -m 0644 -D ${S}/include/pixelflinger/format.h ${D}${includedir}/pixelflinger/format.h
   install -m 0644 -D ${S}/include/pixelflinger/pixelflinger.h ${D}${includedir}/pixelflinger/pixelflinger.h

   install -m 0644 -D ${S}/../50-log.rules ${D}${sysconfdir}/udev/rules.d/50-log.rules

   # Prefer adbd to be located in /sbin for historical reasons
   rm ${D}${bindir}/adbd
   install -m 0755 ${S}/../build/adb/adbd -D ${D}/sbin/adbd
   install -m 0755 ${S}/adb/start_adbd -D ${D}${sysconfdir}/init.d/adbd
   install -m 0755 ${S}/usb/start_usb -D ${D}${sysconfdir}/init.d/usb
   install -m 0755 ${S}/usb/usb_composition -D ${D}${bindir}/
   install -d ${D}${bindir}/usb/compositions/
   install -m 0755 ${S}/usb/compositions/* -D ${D}${bindir}/usb/compositions/
   install -m 0755 ${WORKDIR}/composition-sierra -D ${D}${bindir}/usb/compositions/sierra
   ln -s /usr/bin/usb/compositions/sierra ${D}${bindir}/usb/boot_hsusb_composition
   ln -s /usr/bin/usb/compositions/sierra ${D}${bindir}/usb/boot_hsic_composition
}

PACKAGES =+ "${PN}-libmincrypt-dev ${PN}-libmincrypt-staticdev"
FILES_${PN}-libmincrypt-dev        = "${libdir}/libmincrypt.la ${libdir}/pkgconfig/libmincrypt.pc"
FILES_${PN}-libmincrypt-staticdev  = "${libdir}/libmincrypt.a"

PACKAGES =+ "${PN}-libcutils-dbg ${PN}-libcutils ${PN}-libcutils-dev ${PN}-libcutils-staticdev"
FILES_${PN}-libcutils-dbg    = "${libdir}/.debug/libcutils.*"
FILES_${PN}-libcutils        = "${libdir}/libcutils.so.*"
FILES_${PN}-libcutils-dev    = "${libdir}/libcutils.so ${libdir}/libcutils.la ${libdir}/pkgconfig/libcutils.pc ${includedir}"
FILES_${PN}-libcutils-staticdev = "${libdir}/libcutils.a"

PACKAGES =+ "${PN}-adbd-dbg ${PN}-adbd"
FILES_${PN}-adbd-dbg = "/sbin/.debug/adbd"
FILES_${PN}-adbd     = "/sbin/adbd ${sysconfdir}/init.d/adbd"

PACKAGES =+ "${PN}-usb"
FILES_${PN}-usb     = "${sysconfdir}/init.d/usb ${bindir}/usb_composition ${bindir}/usb/compositions/* ${bindir}/usb/*"

PACKAGES =+ "${PN}-liblog-dbg ${PN}-liblog ${PN}-liblog-dev ${PN}-liblog-staticdev"
FILES_${PN}-liblog-dbg    = "${libdir}/.debug/liblog.* ${bindir}/.debug/logcat"
FILES_${PN}-liblog        = "${libdir}/liblog.so.* ${bindir}/logcat ${sysconfdir}/udev/rules.d/50-log.rules"
FILES_${PN}-liblog-dev    = "${libdir}/liblog.so ${libdir}/liblog.la"
FILES_${PN}-liblog-staticdev = "${libdir}/liblog.a"

