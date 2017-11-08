inherit swi-image-minimal

require mdm9x28-image.inc

require ../../../meta-swi-mdm9xxx/recipes-core/images/mdm9xxx-qemu-image-minimal.inc

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${DEPLOY_DIR_IMAGE}/rootfs
}

do_rootfs[postfuncs] += "rootfs_symlink"

