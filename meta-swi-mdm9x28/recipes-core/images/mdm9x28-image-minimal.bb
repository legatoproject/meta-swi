inherit swi-image-minimal

require mdm9x28-image.inc

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.2k.default ${DEPLOY_DIR_IMAGE}/rootfs
}

do_rootfs[postfuncs] += "rootfs_symlink"

