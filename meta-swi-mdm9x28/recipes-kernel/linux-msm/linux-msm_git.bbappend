KBUILD_DEFCONFIG_SNIPPETS_append := " ${@bb.utils.contains('MACHINE_FEATURES', 'nfsclient', '${THISDIR}/files/nfs-client.cfg', '', d)} \"
