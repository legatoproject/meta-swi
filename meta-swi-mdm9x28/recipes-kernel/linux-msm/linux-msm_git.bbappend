KBUILD_DEFCONFIG_SNIPPETS_append := " ${@bb.utils.contains('MACHINE_FEATURES', 'nfsclient', '${THISDIR}/files/nfs-client.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS_append := " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', '${THISDIR}/files/tiwifi.cfg', '', d)} \"
KBUILD_DEFCONFIG_SNIPPETS_append := " ${@bb.utils.contains('MACHINE_FEATURES', 'qcawifibt', '${THISDIR}/files/qcawifi.cfg', '', d)} \"
