INSANE_SKIP:${PN} += "already-stripped"

SRCREV = "${AUTOREV}"

LK_TARGET = "mdm9607"

inherit android-signing
LK_HASH_MODE = "android_signing"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}'"
EXTRA_OEMAKE:append = " SIGNED_KERNEL=1"
CC:append = " -Wno-error=format-security"

do_configure:prepend() {
    if [ -d "${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra" ]; then
        rm -f ${S}/app/aboot/sierra
        ln -sf ${LINUX_REPO_DIR}/arch/arm/mach-msm/sierra ${S}/app/aboot/sierra
    fi
}

do_install:prepend() {
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
