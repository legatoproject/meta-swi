FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# use 9120 in temporarily, will update to actual pid when sierra driver ready.
#SRC_URI_append += " file://9120"
#COMPOSITION = "9102"
#COMPOSITION_sdxprairie="9120"

SRC_URI_append += " file://target"
SRC_URI_append += " file://start_usb"


do_install_append() {
   #install -d ${D}${base_sbindir}/usb/compositions/
   #install -m 0755 ${WORKDIR}/9120 -D ${D}${base_sbindir}/usb/compositions/
   install -m 0755 ${WORKDIR}/target -D ${D}${base_sbindir}/usb/
   install -m 0750 ${WORKDIR}/start_usb -D ${D}${sysconfdir}/initscripts/usb
}
