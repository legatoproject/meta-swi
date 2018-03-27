inherit swi-image-initramfs

IMAGE_FSTYPES += "cpio.gz"

PACKAGE_INSTALL_append = " initramfs-mdminit"

fakeroot do_filter_rootfs_append () {

    cd ${IMAGE_ROOTFS}

    # Populate rootfs with some devices
    mknod dev/ttyHSL0 c 249 0
    mknod dev/ttyHSL1 c 249 1
}

