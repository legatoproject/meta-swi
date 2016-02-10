DESCRIPTION = "A small image just capable of allowing SWI mdm9x40 to boot (modified for performance tests)."

inherit swi-image-minimal

require mdm9x40-image.inc

IMAGE_TYPE = "testperf"

IMAGE_INSTALL += "iozone3"
IMAGE_INSTALL += "curl"
IMAGE_INSTALL += "gnutls"
IMAGE_INSTALL += "libtasn1"
IMAGE_INSTALL += "zlib"
IMAGE_INSTALL += "libgcrypt"
IMAGE_INSTALL += "iperf"
IMAGE_INSTALL += "rt-tests"
#IMAGE_INSTALL += "kernel-module-nf-nat-ftp"
#IMAGE_INSTALL += "kernel-module-nf-conntrack-ftp"

do_rootfs[depends] += "mdm9x40-image-initramfs:do_rootfs"
do_rootfs[depends] += "mdm9x40-image-minimal:do_rootfs"

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.2k.yaffs2 ${DEPLOY_DIR_IMAGE}/rootfs-${IMAGE_TYPE}
}

do_rootfs[postfuncs] += "rootfs_symlink"


