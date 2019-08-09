# Override some of the files shipped with original recipe
FILESEXTRAPATHS_append := ":${THISDIR}/files"
SRC_URI += "file://usb/target \
            file://usb/compositions/90FE \
            file://usb/usb.service \
            "

# Customize gadget composition for Sierra Wireless design
COMPOSITION_sdxprairie = "90FE"

do_install_append() {
   rm -f ${D}${base_sbindir}/usb/target
   install -m 0755 ${WORKDIR}/usb/target -D ${D}${base_sbindir}/usb/
   rm -f ${D}${base_sbindir}/usb/compositions/90FE
   install -m 0755 ${WORKDIR}/usb/compositions/90FE -D ${D}${base_sbindir}/usb/compositions/90FE

   install -m 0644 ${WORKDIR}/usb/usb.service -D ${D}${systemd_unitdir}/system/usb.service
   ln -sf ${systemd_unitdir}/system/usb.service ${D}${systemd_unitdir}/system/multi-user.target.wants/usb.service
   ln -sf ${systemd_unitdir}/system/usb.service ${D}${systemd_unitdir}/system/ffbm.target.wants/usb.service
}
