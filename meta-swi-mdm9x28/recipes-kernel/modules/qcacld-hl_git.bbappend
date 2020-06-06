# Choose a git version aligned to the kernel version.
def version_git(d):
    kernel_version = d.getVar('KERNEL_VERSION')
    if kernel_version.startswith("4.14."):
        # Tag LE.UM.1.1-88300-9x07
        return "d515a09b2a60e63571046c9475ffcb3095eb5b98"
    else:
        # Tag LE.UM.1.1-55100-9x07
        return "62c47a8b1039f05d0d5f4249fa8b9e1c76ca8b6b"

SRCREV = '${@version_git(d)}'

# Version
PR = "r1"

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




