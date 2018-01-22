SRCREV = "${AUTOREV}"
LK_REPO ??= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x28le20-swi"

LK_TARGET = "mdm9607"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

do_patch() {
    if [ ! -L "${S}/app/aboot/sierra" -a -d "${LINUX_REPO_DIR}/../arch/arm/mach-msm/sierra" ]; then
        ln -sf ${LINUX_REPO_DIR}/../arch/arm/mach-msm/sierra ${S}/app/aboot/sierra
    fi
}

do_install() {
    install -d ${D}/boot
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${D}/boot
    fi
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}

    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}

    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}
    fi

    if [ -f "${B}/build-${LK_TARGET}/lkversion" ] ; then
        cp ${B}/build-${LK_TARGET}/lkversion ${DEPLOY_DIR_IMAGE}/lk.version
    fi
}

# Dependency because do_deploy copies files created by do_install.
addtask deploy after do_install
