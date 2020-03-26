PACKAGECONFIG_remove = "gnutls libidn"
PACKAGECONFIG_append = " ssl"

FILESEXTRAPATHS_prepend := "${THISDIR}/curl:"
CURL_7_61_0_PATCHES = "file://CVE-2018-16890.patch \
                       file://CVE-2019-3822.patch \
                       file://CVE-2019-3823.patch"

SRC_URI += "${@oe.utils.conditional('PV', '7.61.0', '${CURL_7_61_0_PATCHES}', '', d)}"
