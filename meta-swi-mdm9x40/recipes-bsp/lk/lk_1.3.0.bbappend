inherit localgit

SRCREV = "${AUTOREV}"

SRC_URI = ""
SRC_DIR = "${LK_REPO}"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}'"
CC_append += " -Wno-error=format-security"

INSANE_SKIP_${PN} += "already-stripped"

DEPENDS += "openssl-native python-native"

LK_HASH_MODE = "dual_system"

do_install_prepend() {
    if [ -f "${B}/../../appsboot.mbn" ] ; then
        install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    fi
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
    fi
}
