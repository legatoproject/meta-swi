PACKAGECONFIG_remove = "gnutls"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://memfd-header-detect.diff"
