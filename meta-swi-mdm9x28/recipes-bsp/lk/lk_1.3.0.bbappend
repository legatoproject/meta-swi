inherit localgit

SRCREV = "${AUTOREV}"

SRC_URI = ""
SRC_DIR = "${LK_REPO}"

LK_TARGET = "mdm9607"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}'"

do_patch() {
    if [ ! -L "${S}/app/aboot/sierra" -a -d "${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra" ]; then
        ln -sf ${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra ${S}/app/aboot/sierra
    fi
}

do_install_prepend() {
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
    fi
    if [ -f "${B}/../../appsboot_rw_ima.mbn" ] ; then
        install ${B}/../../appsboot_rw_ima.mbn ${B}/build-${LK_TARGET}/
    fi
}
