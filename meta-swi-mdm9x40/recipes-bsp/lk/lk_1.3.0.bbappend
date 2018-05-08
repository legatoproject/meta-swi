inherit localgit

SRCREV = "${AUTOREV}"

SRC_URI = ""
SRC_DIR = "${LK_REPO}"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

INSANE_SKIP_${PN} += "already-stripped"

LIBGCC = "${STAGING_LIBDIR}/${TARGET_SYS}/6.2.0/libgcc.a"

EXTRA_OEMAKE += "ARCH='${TARGET_ARCH}' CC='${CC}' LIBGCC='${LIBGCC}'"

# Enable hardfloat
EXTRA_OEMAKE_append = " ${@base_conditional('ARM_FLOAT_ABI', 'hard', 'ENABLE_HARD_FPU=1', '', d)}"

add_hash_segment() {
    IMAGE_NAME=$1
    cd ${B}
    if [ -f "${B}/build-${LK_TARGET}/$IMAGE_NAME.mbn" ] ; then
        mv ${B}/build-${LK_TARGET}/$IMAGE_NAME.mbn ${B}/../../$IMAGE_NAME.mbn
        python ${THISDIR}/files/add_hash_segment.py image=${B}/../../$IMAGE_NAME.mbn imageType=APBL of=${B}/build-${LK_TARGET}/unsigned
        install ${B}/build-${LK_TARGET}/unsigned/$IMAGE_NAME.umbn ${B}/../../$IMAGE_NAME.mbn
    fi
}

do_add_hash() {
    add_hash_segment appsboot
    add_hash_segment appsboot_rw
}

addtask add_hash after do_compile before do_install

do_install_prepend() {
    install ${B}/../../appsboot.mbn ${B}/build-${LK_TARGET}/
    if [ -f "${B}/../../appsboot_rw.mbn" ] ; then
        install ${B}/../../appsboot_rw.mbn ${B}/build-${LK_TARGET}/
    fi
}
