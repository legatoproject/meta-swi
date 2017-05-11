require cryptsetup_${PV}.bb
SUMMARY = "Manage plain dm-crypt and LUKS encrypted volumes"
DESCRIPTION = "${nativesdk-cryptsetup}"
DEPENDS = ""
PROVIDES += "nativesdk-cryptsetup"

inherit nativesdk

DEPENDS = "nativesdk-device-mapper nativesdk-popt libxml2-native lcms-native m4-native nativesdk-util-linux libgcrypt-native openssl-native"

S = "${WORKDIR}/cryptsetup-${PV}"

RDEPENDS_${PN} = "nativesdk-device-mapper"
do_compile[depends] += "nativesdk-device-mapper:do_populate_sysroot"
