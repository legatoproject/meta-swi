KBUILD_DEFCONFIG_SNIPPETS:append := " ${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', '${THISDIR}/linux-quic/tiwifi.cfg', '', d)} \"
