LIC_FILES_CHKSUM = "file://../startlegato.sh;startline=2;endline=2;md5=2baae491bdfa9b64df1c93ed39b2e575"

# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

INITSCRIPT_PARAMS = "start 32 S . stop 68 S ."
