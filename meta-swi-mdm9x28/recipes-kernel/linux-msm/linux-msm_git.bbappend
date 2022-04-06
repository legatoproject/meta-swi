KBUILD_DEFCONFIG_SNIPPETS:append := " ${@bb.utils.contains('MACHINE_FEATURES', 'nfsclient', '${THISDIR}/files/nfs-client.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS:append := " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', '${THISDIR}/files/tiwifi.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS:append := " ${@bb.utils.contains('MACHINE_FEATURES', 'qcawifi', '${THISDIR}/files/qcawifi.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS:append := " ${@bb.utils.contains('MACHINE_FEATURES', 'qcabt', '${THISDIR}/files/qcabt.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'msmaudio', '${THISDIR}/files/msm-audio.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'lxc', '${THISDIR}/files/lxc.cfg', '', d)} \"

# These 3 methods are forcing initramfs bundling process to use
# cpio.gz file as kernel initramfs instead of standard cpio. This
# saves us some RAM when kernel image is loading, and it will prevent
# kernel uncompression process from overwriting kernel image.
do_bundle_initramfs:prepend() {
    # Tell kernel_do_compile that do_bundle_initramfs() is calling it.
    initramfs_running="1"
}

do_bundle_initramfs:append() {
    # Clear it after initramfs bundling is done.
    initramfs_running="0"
}

kernel_do_compile:prepend() {
    if [ "x${initramfs_running}" = "x1" ] ; then
        use_alternate_initrd=CONFIG_INITRAMFS_SOURCE="${DEPLOY_DIR_IMAGE}/${INITRAMFS_IMAGE_NAME}.cpio.gz"
    fi
}
