# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

INITSCRIPT_PARAMS = "start 98 S . stop 06 S ."
