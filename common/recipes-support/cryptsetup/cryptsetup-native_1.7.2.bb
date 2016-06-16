require cryptsetup_${PV}.bb
SUMMARY = "Manage plain dm-crypt and LUKS encrypted volumes"
DESCRIPTION = "${cryptsetup-alternatives}"
DEPENDS = ""
PROVIDES += "cryptsetup-native"

inherit native

DEPENDS = "device-mapper-native popt-native libxml2-native lcms-native m4-native util-linux-native libgcrypt-native openssl-native"

S = "${WORKDIR}/cryptsetup-${PV}"
