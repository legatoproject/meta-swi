SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x40-swi"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

INSANE_SKIP_${PN} += "already-stripped"

do_tag_lk() {
    # We remove the sierra_lkversion.h to avoid this file to be counted in sha1
    ( cd ${S}; \
        echo "#define LKVERSION  \"${PV}_"`for file in $(find -type f -not -regex '.*\(pc\|git\|build-\|patches\).*'); do \
        sha256sum $file; done | \
        sort | grep -v sierra_lkversion.h | awk '{print $1}' | sha256sum | cut -c 1-10 -`"\"" ) >${S}/app/aboot/sierra_lkversion.h
}

addtask tag_lk before do_compile after do_configure

add_hash_segment() {
    IMAGE_NAME=$1
    if [ -f "${B}/build-${LK_TARGET}/$IMAGE_NAME.mbn" ] ; then
        mv ${B}/build-${LK_TARGET}/$IMAGE_NAME.mbn ${B}/../../$IMAGE_NAME.mbn
        python ${THISDIR}/files/add_hash_segment.py image=${B}/../../$IMAGE_NAME.mbn imageType=APBL of=${B}/build-${LK_TARGET}/unsigned
        cp ${B}/build-${LK_TARGET}/unsigned/$IMAGE_NAME.umbn  ${B}/build-${LK_TARGET}/$IMAGE_NAME.mbn
    fi
}

do_add_hash() {
    add_hash_segment appsboot
    add_hash_segment appsboot_rw
}

addtask add_hash after do_compile before do_install

do_install() {
    install -d ${D}/boot
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${D}/boot
    fi
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}
    fi
}
