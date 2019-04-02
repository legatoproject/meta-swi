# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

VER_1_0_2p_PATCHES := "file://CVE-2018-0734.patch \
                       file://CVE-2019-1559_1.patch \
                       file://CVE-2019-1559_2.patch"

SRC_URI += "${@oe.utils.conditional('PV', '1.0.2p', '${VER_1_0_2p_PATCHES}', '', d)}"
