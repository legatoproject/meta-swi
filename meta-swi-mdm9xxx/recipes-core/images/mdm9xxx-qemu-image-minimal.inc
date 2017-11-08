blank_flashimage() {
    echo "Erasing flash image"
    (dd if=/dev/zero bs=1M count=256 | tr '\000' '\377' | dd of=${DEPLOY_DIR_IMAGE}/rawflash iflag=fullblock bs=1M count=256)
}

do_generate_flashimage() {
    if [ "${QEMU_BUILD}" = "on" ]; then
        blank_flashimage
        echo "Installing ROOTFS into flash image"
        dd if=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${QEMU_ROOTFS_TYPE} of=${DEPLOY_DIR_IMAGE}/rawflash conv=notrunc bs=256K
    fi
}

addtask generate_flashimage after do_image_complete and before do_generate_cwe
