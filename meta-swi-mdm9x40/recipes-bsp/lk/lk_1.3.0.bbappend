# Tag LNX.LE.5.1-66215-9x40
SRCREV = "ef27e0fd7d68c886e318f35dda5acc9e89281edd"
LK_REPO = "git://codeaurora.org/kernel/lk;branch=LNX.LE.5.1_rb1.6"

LK_TARGET = "mdm9640"

do_install() {
    install -d ${D}/boot
    install ${S}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${S}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
}
