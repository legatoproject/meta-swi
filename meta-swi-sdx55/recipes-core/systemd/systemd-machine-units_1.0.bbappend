FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " file://data-ram.mount \
                    file://run.env \
                    file://mount_swirw.sh \
                    file://mount_swirw.service \
                  "

fix_sepolicies_append () {
    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/data-ram.mount
}

do_install_append () {
    install -d 0644 ${D}${systemd_unitdir}/system/local-fs-pre.target.requires

    #As this folder include more log files, use ram to avoid flash broken.
    if ${@bb.utils.contains('DISTRO_FEATURES','userfs-in-ram','true','false',d)}; then
        install -m 0644 ${WORKDIR}/data-ram.mount ${D}${systemd_unitdir}/system/data.mount
    fi
    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env

    install -m 0744 ${WORKDIR}/mount_swirw.sh ${D}${sysconfdir}/initscripts/mount_swirw.sh
    install -m 0644 ${WORKDIR}/mount_swirw.service ${D}${systemd_unitdir}/system/mount_swirw.service
    ln -sf ${systemd_unitdir}/system/mount_swirw.service \
           ${D}${systemd_unitdir}/system/local-fs-pre.target.requires/mount_swirw.service
}
