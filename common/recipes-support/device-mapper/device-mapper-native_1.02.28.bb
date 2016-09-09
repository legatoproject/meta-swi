require device-mapper.inc

SUMMARY = "device-mapper-native"
DESCRIPTION = "LVM2 need this lib libdevmapper."

PROVIDES += "device-mapper-native"

inherit native
DEPENDS = "popt-native libxml2-native lcms-native m4-native util-linux-native libgcrypt-native openssl-native"

S = "${WORKDIR}/device-mapper.${PV}"
B = "${S}"
O = "${S}"

