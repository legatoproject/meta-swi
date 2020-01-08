FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://0001-ALPC-232-Provide-factory-default-recovery-mechanism.patch \
           "

do_install_append() {
    rm -f ${D}${sysconfdir}/run.env
    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env
    # Append common functions from meta-swi-mdm9xxx layer
    cat ${WORKDIR}/functions.env >> ${D}${sysconfdir}/run.env
    sed -i 's#\(root:x:0:0:.*\):/bin/.*sh#\1:/usr/sbin/loginNagger#' ${D}${sysconfdir}/passwd

    # To solve the roll-back issue in LXSWIREF-1510, a symbolic link to the
    # loginNagger script is created in /etc/profile.d/, so that /etc/profile
    # will invoke it AFTER login.
    # For FX30, since the loginNagger is run as default login shell, keeping the
    # link will make the script been called twice. Therefore, it needs to be
    # removed
    if [ -h ${D}${sysconfdir}/profile.d/loginNagger ]; then
        rm ${D}${sysconfdir}/profile.d/loginNagger

        # Also remove the profile.d directory if empty
        if [ $(ls -1 "${D}${sysconfdir}/profile.d/" | wc -l) -eq 0 ]; then
            rm -r "${D}${sysconfdir}/profile.d/"
        fi
    fi
}
