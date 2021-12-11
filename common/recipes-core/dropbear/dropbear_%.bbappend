FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://init.wrapper"
# CVE-2020-36254 is patched in 2020.79. The following patch can be removed once poky upgrades
# dropbear to that version or higher.
SRC_URI += "${@oe.utils.version_less_or_equal('PV', '2019.78', 'file://CVE-2020-36254.patch', '', d)}"

INITSCRIPT_NAME = "dropbear.wrapper"
INITSCRIPT_PARAMS = "start 95 S . stop 90 S ."

do_install_append() {
    install -m 0755 ${WORKDIR}/init.wrapper ${D}${sysconfdir}/init.d/dropbear.wrapper
}
