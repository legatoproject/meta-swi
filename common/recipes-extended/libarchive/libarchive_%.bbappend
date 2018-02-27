# Force Yocto to install bsdtar on target and SDK.
# Generic RDEPENDS_${PN}_append will complain about
# not being able to find bsdtar-native, so we don't
# do it.
RDEPENDS_${PN}_append_class-target = " bsdtar"
RDEPENDS_${PN}_append_class-nativesdk = " bsdtar"

# Enable extended attributes for all targets.
PACKAGECONFIG_append = " xattr"
