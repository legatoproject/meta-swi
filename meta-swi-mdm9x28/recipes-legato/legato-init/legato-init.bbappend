# look for files in the layer first
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

INITSCRIPT_PARAMS = "start 32 S . stop 68 S ."
