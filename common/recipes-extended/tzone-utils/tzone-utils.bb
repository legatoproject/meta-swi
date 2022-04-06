SUMMARY = "timezone utilities"
DESCRIPTION = "Manipulates timezone on system level."

# Where to find additional files (patches, etc.).
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}_files:"

# Package revision number. Change "r" number if you change
# anything in this package (e.g. add patch, remove patch,
# change dependencies, etc.).
PR = "r0"

HOMEPAGE = ""
LICENSE = "MPLv2"
# Make sure that there is 'file://../COPYING...' in order to avoid
# "LIC_FILES_CHKSUM points to an invalid file" error.
LIC_FILES_CHKSUM = "file://../COPYING;md5=9741c346eef56131163e13b9db1241b3"

# Where to find source code for this package.
SRC_URI = "file://COPYING"
SRC_URI += "file://tzoneset"

do_install() {

    # Install required files.
    install -m 0755 ${WORKDIR}/tzoneset -D ${D}${exec_prefix}/sbin/tzoneset
}
