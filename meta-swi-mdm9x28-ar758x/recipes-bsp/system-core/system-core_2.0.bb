
DESCRIPTION = "Android system/core components"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.1.2-47600-9x07
SRCREV = "276e8815d004acffacd3d4db16a4c63383ae3e85"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.1.c2-rel"

SRC_URI  = "${SYSTEMCORE_REPO}"

SRC_URI += "file://0001-Fix-adbd-crash-issue.patch"
SRC_URI += "file://0001-Fix-compile-errors-of-system-core-by-GCC6.2.0.patch"
SRC_URI += "file://composition-sierra_dev"
SRC_URI += "file://start_usb"
SRC_URI += "file://fix-big-endian-build.patch"
# Start adb after iSerial is set.
SRC_URI += "file://0002-Fix-usb-serial-conflict.patch"
# Fix gcc 7 build
SRC_URI += "file://0003-include-utils-Vector.h-remove-nonsensical-libresourc.patch"
SRC_URI += "file://0004-libbacktrace-Use-ucontext_t-instead-of-struct-uconte.patch"

inherit autotools pkgconfig

S = "${WORKDIR}/git"

PR = "r2"

DEPENDS = "virtual/kernel openssl glib-2.0 libselinux safe-iop ext4-utils libunwind libcutils libmincrypt libcap"

EXTRA_OECONF = " --with-host-os=${HOST_OS} --with-glib"
EXTRA_OECONF_append = " --with-sanitized-headers=${STAGING_DIR_TARGET}${KERNEL_SRC_PATH}/usr/include"
EXTRA_OECONF_append = " --with-logd-logging"

# Disable adb root privileges in USER builds for msm targets
EXTRA_OECONF_append_msm = "${@oe.utils.conditional('USER_BUILD','1',' --disable-adb-root','',d)}"

EXTRA_OEMAKE += " LIBS='-lpthread'"

CPPFLAGS += "-I${STAGING_INCDIR}/ext4_utils"
CPPFLAGS += "-I${STAGING_INCDIR}/libselinux"
CPPFLAGS += "-I${STAGING_INCDIR}/libunwind"

CPPFLAGS_append_apq8053 += " -DTARGET_IS_64_BIT"
CPPFLAGS_append_apq8017 += " -DTARGET_IS_64_BIT"
CPPFLAGS_append_apq8096 += " -DTARGET_IS_64_BIT"
COMPOSITION         = "9025"
COMPOSITION_apq8009 = "9091"
COMPOSITION_apq8053 = "901D"
COMPOSITION_apq8096 = "901D"
COMPOSITION_apq8098 = "901D"

userfsdatadir="/etc/data"

do_install_append() {
    install -m 0755 ${S}/adb/launch_adbd -D ${D}${sysconfdir}/launch_adbd
    install -d ${D}${base_sbindir}
    install -m 0755 ${S}/usb/usb_composition -D ${D}${base_sbindir}/
    install -d ${D}${base_sbindir}/usb/compositions/
    install -d ${D}${bindir}
    install -d ${D}${bindir}/usb/compositions/
    install -m 0755 ${S}/usb/compositions/* -D ${D}${bindir}/usb/compositions/
    install -d ${D}${userfsdatadir}/usb/
    install -m 0755 ${S}/usb/compositions/hsic_next -D ${D}${userfsdatadir}/usb/
    install -m 0755 ${S}/usb/compositions/hsusb_next -D ${D}${userfsdatadir}/usb/
    install -m 0755 ${S}/usb/target -D ${D}${base_sbindir}/usb/
    install -d ${D}${base_sbindir}/usb/debuger/
    install -m 0755 ${S}/usb/debuger/debugFiles -D ${D}${base_sbindir}/usb/debuger/
    install -m 0755 ${S}/usb/debuger/help -D ${D}${base_sbindir}/usb/debuger/
    install -m 0755 ${S}/usb/debuger/usb_debug -D ${D}${base_sbindir}/
    ln -s  ${bindir}/compositions/${COMPOSITION} ${D}${userfsdatadir}/usb/boot_hsusb_composition
    ln -s  ${bindir}/compositions/empty ${D}${userfsdatadir}/usb/boot_hsic_composition

    install -m 0755 ${S}/adb/start_adbd -D ${D}${sysconfdir}/init.d/adbd
    install -m 0755 ${S}/logd/start_logd -D ${D}${sysconfdir}/init.d/logd
    install -m 0755 ${S}/usb/start_usb -D ${D}${sysconfdir}/init.d/usb
    install -m 0755 ${S}/rootdir/etc/init.qcom.post_boot.sh -D ${D}${sysconfdir}/init.d/init_post_boot

    install -m 0755 ${WORKDIR}/composition-sierra_dev -D ${D}${bindir}/usb/compositions/sierra_dev
    ln -s ${bindir}/usb/compositions/sierra_dev ${D}${bindir}/usb/boot_hsusb_composition
    ln -s ${bindir}/usb/compositions/empty      ${D}${bindir}/usb/boot_hsic_composition

    # Simpler usb start-up script than the one provided on CodeAurora
    install -m 0755 ${WORKDIR}/start_usb -D ${D}${sysconfdir}/init.d/usb
}
INITSCRIPT_PACKAGES =+ "${PN}-adbd"
INITSCRIPT_NAME_${PN}-adbd = "adbd"
INITSCRIPT_PARAMS_${PN}-adbd = "start 96 S ."

INITSCRIPT_PACKAGES =+ "${PN}-usb"
INITSCRIPT_NAME_${PN}-usb = "usb"
INITSCRIPT_PARAMS_${PN}-usb = "start 09 S ."

INITSCRIPT_PACKAGES =+ "${PN}-debuggerd"
INITSCRIPT_NAME_${PN}-debuggerd = "init_debuggerd"
INITSCRIPT_PARAMS_${PN}-debuggerd = "start 31 2 3 4 5 ."
INITSCRIPT_PARAMS_${PN}-debuggerd += "stop 38 6 ."

INITSCRIPT_PACKAGES =+ "${PN}-logd"
INITSCRIPT_NAME_${PN}-logd = "logd"
INITSCRIPT_PARAMS_${PN}-logd = "start 10  2 3 4 5 ."
INITSCRIPT_PARAMS_${PN}-logd += "stop 39  6 ."

INITSCRIPT_PACKAGES =+ "${PN}-post-boot"
INITSCRIPT_NAME_${PN}-post-boot = "init_post_boot"
INITSCRIPT_PARAMS_${PN}-post-boot = "start 90 2 3 4 5 ."

inherit update-rc.d

PACKAGE_DEBUG_SPLIT_STYLE = 'debug-without-src'

PACKAGES =+ "${PN}-adbd-dbg ${PN}-adbd ${PN}-adbd-dev"
FILES_${PN}-adbd-dbg = "${base_sbindir}/.debug/adbd ${libdir}/.debug/libadbd.*"
FILES_${PN}-adbd     = "${base_sbindir}/adbd ${sysconfdir}/init.d/adbd ${libdir}/libadbd.so.*"
FILES_${PN}-adbd    += "${sysconfdir}/launch_adbd ${sysconfdir}/initscripts/adbd"
FILES_${PN}-adbd-dev = "${libdir}/libadbd.so ${libdir}/libadbd.la"

PACKAGES =+ "${PN}-usb-dbg ${PN}-usb"
FILES_${PN}-usb-dbg  = "${bindir}/.debug/usb_composition_switch"
FILES_${PN}-usb      = "${sysconfdir}/init.d/usb ${base_sbindir}/usb_composition ${bindir}/usb_composition_switch ${base_sbindir}/usb/compositions/*"
FILES_${PN}-usb     += "${userfsdatadir}/usb/*"
FILES_${PN}-usb     += "${base_sbindir}/usb/* ${base_sbindir}/usb_debug ${base_sbindir}/usb/debuger/* ${bindir}/usb/*"
FILES_${PN}-usb     += "${sysconfdir}/initscripts/usb"

PACKAGES =+ "${PN}-post-boot"
FILES_${PN}-post-boot  = "${sysconfdir}/init.d/init_post_boot"
FILES_${PN}-post-boot += "${sysconfdir}/initscripts/init_post_boot"
INSANE_SKIP_${PN}-post-boot = "file-rdeps"

PACKAGES =+ "${PN}-logd-dbg ${PN}-logd"
FILES_${PN}-logd-dbg  = "${base_sbindir}/.debug/logd"
FILES_${PN}-logd      = "${sysconfdir}/init.d/logd ${base_sbindir}/logd"
FILES_${PN}-logd     += "${sysconfdir}/initscripts/logd"

PACKAGES =+ "${PN}-debuggerd-dbg ${PN}-debuggerd"
FILES_${PN}-debuggerd-dbg  = "${base_sbindir}/.debug/debuggerd ${base_sbindir}/.debug/debuggerd64 "
FILES_${PN}-debuggerd      = "${sysconfdir}/init.d/init_debuggerd ${base_sbindir}/debuggerd ${base_sbindir}/debuggerd64"

PACKAGES =+ "${PN}-leprop-dbg ${PN}-leprop"
FILES_${PN}-leprop-dbg  = "${base_sbindir}/.debug/leprop-service ${bindir}/.debug/getprop ${bindir}/.debug/setprop"
FILES_${PN}-leprop      = "${base_sbindir}/leprop-service ${bindir}/getprop ${bindir}/setprop ${sysconfdir}/proptrigger.sh ${sysconfdir}/proptrigger.conf"

FILES_${PN}-dbg  = "${bindir}/.debug/* ${libdir}/.debug/*"
FILES_${PN}      = "${bindir}/* ${libdir}/pkgconfig/* ${libdir}/*.so.* "
FILES_${PN}-dev  = "${libdir}/*.so ${libdir}/*.la ${includedir}*"
