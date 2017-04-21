SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x28le101-swi"

LK_TARGET = "mdm9607"

inherit android-signing

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"
EXTRA_OEMAKE_append = " SIGNED_KERNEL=1"

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

    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn.unsigned

    # sign the image
    android_signature_add /aboot ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}/appsboot.mbn

    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}
    fi

    cp ${B}/build-${LK_TARGET}/lkversion ${DEPLOY_DIR_IMAGE}/lk.version
}

# Dependency because do_deploy copies files created by do_install.
addtask deploy after do_install
