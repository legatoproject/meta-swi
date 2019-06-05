PACKAGECONFIG_remove = "gnutls"
PACKAGECONFIG_append = " ssl"

FILESEXTRAPATHS_prepend := "${THISDIR}/curl:"
SRC_URI += " file://CVE-2018-16890.patch \
             file://CVE-2019-3822.patch \
             file://CVE-2019-3823.patch \
"

