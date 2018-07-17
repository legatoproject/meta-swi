DESCRIPTION = "Android system/core components"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

PR = "r1"

# Tag LNX.LE.2.0.2-61193-9x15
SRCREV = "aef3f6f231d385d616c09a39e18126fd57256ae9"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=penguin"

SRC_URI  = "${SYSTEMCORE_REPO}"
SRC_URI += "file://50-log.rules"
SRC_URI += "file://0001-Fix-libmincrypt-include-path.patch"

inherit autotools pkgconfig

DEPENDS += "glib-2.0"

S = "${WORKDIR}/git"

ALLOW_EMPTY_${PN} = "1"

INITSCRIPT_PACKAGES = "${PN}-adbd ${PN}-usb"

INITSCRIPT_NAME_${PN}-adbd = "adbd"
INITSCRIPT_PARAMS_${PN}-adbd = "start 96 S ."
INITSCRIPT_NAME_${PN}-usb = "usb"
INITSCRIPT_PARAMS_${PN}-usb = "start 09 S ."

inherit update-rc.d

EXTRA_OEMAKE = "INCLUDES='-I${S}/include'"

patch_adb_shell() {
    # Use /bin/sh instead of /system/bin/sh for adbd
    sed -i "s^/system/bin/sh^/bin/sh^" ${S}/adb/services.c
}
do_patch[postfuncs] += "patch_adb_shell"

do_install_append() {
   install -m 0755 -d ${D}${includedir}/cutils
   install -m 0644  ${S}/include/cutils/* ${D}${includedir}/cutils
   install -m 0644 -D ${S}/include/android/log.h ${D}${includedir}/android/log.h
   install -m 0644 -D ${S}/include/pixelflinger/format.h ${D}${includedir}/pixelflinger/format.h
   install -m 0644 -D ${S}/include/pixelflinger/pixelflinger.h ${D}${includedir}/pixelflinger/pixelflinger.h

   install -m 0644 -D ${WORKDIR}/50-log.rules ${D}${sysconfdir}/udev/rules.d/50-log.rules

   # Prefer adbd to be located in /sbin for historical reasons
   rm ${D}${bindir}/adbd
   install -m 0755 ${B}/adb/adbd -D ${D}/sbin/adbd
   install -m 0755 ${S}/adb/start_adbd -D ${D}${sysconfdir}/init.d/adbd
   install -m 0755 ${S}/usb/start_usb -D ${D}${sysconfdir}/init.d/usb
   install -m 0755 ${S}/usb/usb_composition -D ${D}${bindir}/
   install -d ${D}${bindir}/usb/compositions/
   install -m 0755 ${S}/usb/compositions/* -D ${D}${bindir}/usb/compositions/

   if [ -e "${WORKDIR}/composition-sierra" ]; then
      install -m 0755 ${WORKDIR}/composition-sierra -D ${D}${bindir}/usb/compositions/sierra
      ln -s ${bindir}/usb/compositions/sierra ${D}${bindir}/usb/boot_hsusb_composition
      ln -s ${bindir}/usb/compositions/sierra ${D}${bindir}/usb/boot_hsic_composition
   fi
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

