FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " file://data-ram.mount"

fix_sepolicies_append () {
    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/data-ram.mount
}

do_install_append () {
    #As this folder include more log files, use ram to avoid flash broken.
    if ${@bb.utils.contains('DISTRO_FEATURES','userfs-in-ram','true','false',d)}; then
        install -m 0644 ${WORKDIR}/data-ram.mount ${D}${systemd_unitdir}/system/data.mount
    fi
}
