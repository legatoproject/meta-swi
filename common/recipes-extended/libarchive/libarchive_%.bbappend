# Force Yocto to install bsdtar on target and SDK.
# Generic RDEPENDS_${PN}_append will complain about
# not being able to find bsdtar-native, so we don't
# do it.
RDEPENDS_${PN}_append_class-target = " bsdtar"
RDEPENDS_${PN}_append_class-nativesdk = " bsdtar"

# Enable extended attributes for all targets.
PACKAGECONFIG_append = " xattr"
TARGET_CFLAGS += "-I${WORKDIR}/extra-includes"
EXTRA_OEMAKE += "CFLAGS='${TARGET_CFLAGS}'"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS += "e2fsprogs"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)

    # Handle versions < 3.3.2
    if re.match('3.[12]', pv):
           d.setVar('SRC_URI', srcuri + \
                    ' file://non-recursive-extract-and-list_3.2.2.patch' \
                    ' file://0001-archive_write_disk_posix.c-make-_fsobj-functions-mor.patch' \
                    ' file://0002-Fix-extracting-hardlinks-over-symlinks.patch' \
                    ' file://CVE-2016-10349-CVE-2016-10350.patch' \
                    ' file://CVE-2017-5601.patch')
}

