SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x40-swi"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

do_install() {
    install -d ${D}/boot
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
}
