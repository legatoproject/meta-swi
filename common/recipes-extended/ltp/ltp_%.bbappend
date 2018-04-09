inherit tar-runtime

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://0099-SWI-ltplite.patch"
