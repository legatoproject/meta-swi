INSANE_SKIP_${PN} += "already-stripped"

do_tag_lk() {
    if [ -n "${FW_VERSION}" ]; then
        echo "#define LKVERSION  \"${FW_VERSION}\"" >${S}/app/aboot/sierra_lkversion.h
    else
        echo "#define LKVERSION  \"unknown\"" >${S}/app/aboot/sierra_lkversion.h
    fi
}

addtask tag_lk before do_compile after do_configure

add_hash_segment() {
    IMAGE_NAME=$1
    if [ -f "${B}/../../$IMAGE_NAME.mbn" ] ; then
        python ${THISDIR}/files/add_hash_segment.py image=${B}/../../$IMAGE_NAME.mbn imageType=APBL of=${B}/build-${LK_TARGET}/unsigned
        install ${B}/build-${LK_TARGET}/unsigned/$IMAGE_NAME.umbn ${B}/../../$IMAGE_NAME.mbn
    fi
}

do_add_hash() {
    add_hash_segment appsboot
    add_hash_segment appsboot_rw
}


addtask add_hash after do_compile before do_install

