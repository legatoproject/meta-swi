# Override some of the files shipped with original recipe
FILESEXTRAPATHS_append := ":${THISDIR}/files"
SRC_URI += "file://usb/target file://usb/compositions/90FE"

# Customize gadget composition for Sierra Wireless design
COMPOSITION_sdxprairie = "90FE"

do_install_append() {
   rm -f ${D}${base_sbindir}/usb/target
   install -m 0755 ${WORKDIR}/usb/target -D ${D}${base_sbindir}/usb/
   rm -f ${D}${base_sbindir}/usb/compositions/90FE
   install -m 0755 ${WORKDIR}/usb/compositions/90FE -D ${D}${base_sbindir}/usb/compositions/90FE
}
