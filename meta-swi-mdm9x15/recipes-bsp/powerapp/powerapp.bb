DESCRIPTION = "Powerapp tools"
HOMEPAGE = "http://codeaurora.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# FIXME, DM: Move reboot and shutdown to rcK, because we cannot reboot
# until complete cleanup is done. And shutdown will be faster since only
# one script is executing (rcK).
# However, the real question is, do we really need these two scripts in
# shutdown sequence.

PR = "r0"

SRC_URI = "file://powerapp.tar.gz"

PACKAGES =+ "${PN}-reboot ${PN}-shutdown ${PN}-powerconfig"
FILES_${PN}-reboot = "${sysconfdir}/init.d/reboot"
FILES_${PN}-shutdown = "${sysconfdir}/init.d/shutdown"
FILES_${PN}-powerconfig = "${sysconfdir}/init.d/power_config"

PROVIDES =+ "${PN}-reboot ${PN}-shutdown ${PN}-powerconfig"

inherit autotools

S = "${WORKDIR}/powerapp"

do_install() {
        install -m 0755 ${WORKDIR}/powerapp/powerapp -D ${D}/sbin/powerapp
        install -m 0755 ${WORKDIR}/powerapp/reboot -D ${D}${sysconfdir}/init.d/reboot
        install -m 0755 ${S}/reboot-bootloader -D ${D}/sbin/reboot-bootloader
        install -m 0755 ${S}/reboot-recovery -D ${D}/sbin/reboot-recovery
        install -m 0755 ${S}/reboot-cookie -D ${D}${sysconfdir}/reboot-cookie
        install -m 0755 ${S}/reset_reboot_cookie -D ${D}${sysconfdir}/init.d/reset_reboot_cookie
        install -m 0755 ${WORKDIR}/powerapp/shutdown -D ${D}${sysconfdir}/init.d/shutdown
        install -m 0755 ${WORKDIR}/powerapp/start_power_config -D ${D}${sysconfdir}/init.d/power_config
        pushd ${D}${base_sbindir}
        ln -s powerapp sys_reboot
        ln -s powerapp sys_shutdown
        popd
}

pkg_postinst_${PN}-reboot () {
        [ -n "$D" ] && OPT="-r $D" || OPT="-s"
        update-rc.d $OPT -f reboot remove
        # Take a look at the FIXME comment.
        # update-rc.d $OPT reboot stop 98 K .
}

pkg_postinst_${PN}-shutdown () {
        [ -n "$D" ] && OPT="-r $D" || OPT="-s"
        update-rc.d $OPT -f shutdown remove
        # Take a look at the FIXME comment above.
        # update-rc.d $OPT shutdown stop 99 K .
}

pkg_postinst_${PN}-powerconfig () {
        [ -n "$D" ] && OPT="-r $D" || OPT="-s"
        update-rc.d $OPT -f power_config remove
        update-rc.d $OPT power_config start 50 S . stop 50 S .
}

pkg_postinst_${PN} () {
    [ -n "$D" ] && OPT="-r $D" || OPT="-s"
    update-rc.d $OPT -f reset_reboot_cookie remove
    update-rc.d $OPT reset_reboot_cookie start 55 S .
}
