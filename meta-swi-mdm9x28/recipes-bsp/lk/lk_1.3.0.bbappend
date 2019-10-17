INSANE_SKIP_${PN} += "already-stripped"

SRCREV = "${AUTOREV}"

LK_TARGET = "mdm9607"

inherit android-signing
LK_HASH_MODE = "android_signing"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}'"
EXTRA_OEMAKE_append = " SIGNED_KERNEL=1"
CC_append += " -Wno-error=format-security"

do_configure_prepend() {
    if [ -d "${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra" ]; then
        rm -f ${S}/app/aboot/sierra
        ln -sf ${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra ${S}/app/aboot/sierra
    fi
}

do_install_prepend() {
    if [ -f "${B}/../../appsboot.mbn" ] ; then
        install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    fi
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
    fi
    if [ -f "${B}/../../appsboot_rw_ima.mbn" ] ; then
        install ${B}/../../appsboot_rw_ima.mbn ${B}/build-${LK_TARGET}/
    fi
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}

    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn.unsigned

    # Sign the image.
    # On SysRef branch, default LK binaries are unsigned.
    # On product branch, we continue to sign all LK binaries. So the result cwe can be tested on dev key installed module.
    android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn verity

    if [ -f "${B}/../../appsboot_rw_ima.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw_ima.mbn ${DEPLOY_DIR_IMAGE}/appsboot_rw_ima.mbn.unsigned
        android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot_rw_ima.mbn ${DEPLOY_DIR_IMAGE}/appsboot_rw_ima.mbn verity
    fi

    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}/appsboot_rw.mbn.unsigned
        android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}/appsboot_rw.mbn verity
    fi
}
