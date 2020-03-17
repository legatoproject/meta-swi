FILESEXTRAPATHS_prepend := "${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', '${THISDIR}/${PN}:', '', d)}"
SRC_URI += "${@bb.utils.contains('MACHINE_FEATURES', 'tiwifi', 'file://tiwifi.cfg', '', d)}"
