inherit swi-image-minimal

require mdm9x40-image.inc

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${IMGDEPLOYDIR}/rootfs
}

do_deploy[postfuncs] += "rootfs_symlink"
