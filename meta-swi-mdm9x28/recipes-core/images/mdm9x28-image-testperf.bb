DESCRIPTION = "A small image just capable of allowing SWI mdm9x40 to boot (modified for performance tests)."

inherit swi-image-minimal

require mdm9x28-image.inc

IMAGE_TYPE = "testperf"

IMAGE_INSTALL:append = " iozone3"
IMAGE_INSTALL:append = " curl"
IMAGE_INSTALL:append = " gnutls"
IMAGE_INSTALL:append = " libtasn1"
IMAGE_INSTALL:append = " zlib"
IMAGE_INSTALL:append = " libgcrypt"
IMAGE_INSTALL:append = " iperf3"
IMAGE_INSTALL:append = " rt-tests"
#IMAGE_INSTALL:append = " kernel-module-nf-nat-ftp"
#IMAGE_INSTALL:append = " kernel-module-nf-conntrack-ftp"

do_rootfs[depends] += "mdm9x28-image-initramfs:do_rootfs"
do_rootfs[depends] += "mdm9x28-image-minimal:do_rootfs"

rootfs_symlink() {
    # Provide minimal image as rootfs symlink
    ln -sf ${IMAGE_LINK_NAME}.default ${IMGDEPLOYDIR}/rootfs-${IMAGE_TYPE}
}

do_deploy[postfuncs] += "rootfs_symlink"
