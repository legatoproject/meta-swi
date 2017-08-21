inherit swi-image-minimal

require mdm9x15-image.inc

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.2k.default ${DEPLOY_DIR_IMAGE}/rootfs
}

# The mdm9x15-image.inc recipe brings in some files via SRC_URI
# which create the requirement for a license, even though they
# are not packaged into the image.

python populate_lic_qa_checksum () {
}

do_rootfs[postfuncs] += "rootfs_symlink"
