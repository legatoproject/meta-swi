SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x28le101-swi"

LK_TARGET = "mdm9607"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

do_install() {
    install -d ${D}/boot
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
    cp ${B}/build-${LK_TARGET}/lkversion ${DEPLOY_DIR_IMAGE}/lk.version
}
