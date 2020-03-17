KBUILD_DEFCONFIG_SNIPPETS_append := " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', '${THISDIR}/linux-quic/tiwifi.cfg', '', d)} \"
