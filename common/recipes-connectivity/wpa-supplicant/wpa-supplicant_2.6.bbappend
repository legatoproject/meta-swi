FILESEXTRAPATHS_prepend := "${THISDIR}/wpa-supplicant:"

SRC_URI += " \
            file://defconfig \
	    file://defconfig_qca9377 \
            file://0001-wpa-supplicant-2.6.patch \
         "

do_configure_append() {
    # DM: For now, do this conditionally. However, the fact is that new config
    # file contains only configuration additions, and we should not have
    # any problems replacing old config file with new one.
    if [ "x${ENABLE_QCA9377}" = "x1" ] ; then

        install -m 0644 ${WORKDIR}/defconfig_qca9377 ${B}/.config

        # DM, FIXME: This bellow should be moved into EXTRA_OEMAKE and/or
	# EXTRA_OECONF. However, I am not sure that wpa_supplicant will take
	# this operation properly.
	echo "CFLAGS +=\"-I${STAGING_INCDIR}/libnl3\"" >> wpa_supplicant/.config
        echo "DRV_CFLAGS +=\"-I${STAGING_INCDIR}/libnl3\"" >> wpa_supplicant/.config

        if [ echo "${PACKAGECONFIG}" | grep -qw "openssl" ] ; then
            ssl=openssl
        elif [ echo "${PACKAGECONFIG}" | grep -qw "gnutls" ] ; then
            ssl=gnutls
        fi

        if [ -n "$ssl" ]; then
            sed -i "s/%ssl%/$ssl/" wpa_supplicant/.config
        fi

	# For rebuild
        rm -f wpa_supplicant/*.d wpa_supplicant/dbus/*.d
    fi
}

do_install_append() {
    install -m 0755 -d ${D}/sbin
    ln -s ${sbindir}/wpa_supplicant ${D}/sbin/
    ln -s ${sbindir}/wpa_cli ${D}/sbin/
    ln -s ${bindir}/wpa_passphrase ${D}/sbin/
}

FILES_${PN} += " /sbin"
