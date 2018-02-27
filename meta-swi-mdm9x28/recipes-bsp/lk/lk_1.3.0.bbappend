SRCREV = "${AUTOREV}"
LK_REPO ??= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x28le20-swi"

LK_TARGET = "mdm9607"

inherit android-signing

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"
EXTRA_OEMAKE_append = " SIGNED_KERNEL=1"

do_patch() {
    if [ ! -L "${S}/app/aboot/sierra" -a -d "${LINUX_REPO_DIR}/../arch/arm/mach-msm/sierra" ]; then
        ln -sf ${LINUX_REPO_DIR}/../arch/arm/mach-msm/sierra ${S}/app/aboot/sierra
    fi
}

do_install_prepend() {
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
    fi
}

do_deploy_append() {
    # create an unsigned copy
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn.unsigned

    # sign the image
    android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn
}
