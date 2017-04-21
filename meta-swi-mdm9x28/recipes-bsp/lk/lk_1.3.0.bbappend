inherit localgit

SRCREV = "${AUTOREV}"

SRC_URI = ""
SRC_DIR = "${LK_REPO}"

LK_TARGET = "mdm9607"

inherit android-signing

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}'"
EXTRA_OEMAKE_append = " SIGNED_KERNEL=1"
CC_append += " -Wno-error=format-security"

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

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}

    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn.unsigned

    # sign the image

    if [ -f "${B}/../../appsboot_rw_ima.mbn" ] ; then
        android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot_rw_ima.mbn ${DEPLOY_DIR_IMAGE}/appsboot_rw_ima.mbn.signed verity
        install ${B}/../../appsboot_rw_ima.mbn ${B}/build-${LK_TARGET}/
    fi

    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}
    fi
}
