inherit swi-image-initramfs

IMAGE_FSTYPES += "cpio.gz"

PACKAGE_INSTALL_append = " initramfs-mdminit"

fakeroot do_filter_rootfs_append () {

    cd ${IMAGE_ROOTFS}

    # Populate rootfs with some devices
    [ -e "dev/ttyMSM0" ] || mknod dev/ttyMSM0 c 238 0
}

