require device-mapper.inc

SUMMARY = "nativesdk-device-mapper"
DESCRIPTION = "LVM2 need this lib libdevmapper."

#PROVIDES += "nativesdk-device-mapper"

inherit nativesdk

DEPENDS = "nativesdk-popt nativesdk-libxml2 nativesdk-glibc nativesdk-cmake nativesdk-m4 nativesdk-util-linux libgcrypt-native nativesdk-openssl"

S = "${WORKDIR}/device-mapper.${PV}"
B = "${S}"
O = "${S}"

