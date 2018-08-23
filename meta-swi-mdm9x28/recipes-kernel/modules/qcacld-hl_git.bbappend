# Patches
SRC_URI += " \
            file://0001-compile-options.patch \
           "

# QCA9377 Configuration files.
SRC_URI += "file://WCNSS_cfg.dat \
	    file://WCNSS_qcom_cfg.ini \
	   "

# Add our own QCA9377 config.
do_configure_append() {
    install -m 0644 ${WORKDIR}/WCNSS_cfg.dat ${S}/firmware_bin/
    install -m 0644 ${WORKDIR}/WCNSS_qcom_cfg.ini ${S}/firmware_bin/
}
