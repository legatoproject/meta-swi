SUMMARY = "update system ld cache"
DESCRIPTION = "Updates /etc/ld.so.cache file."

# Where to find additional files (patches, etc.).
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Package revision number. Change "r" number if you change
# anything in this package (e.g. add patch, remove patch,
# change dependencies, etc.).
PR = "r0"

HOMEPAGE = ""
LICENSE = "MPLv2"
# Make sure that there is 'file://../COPYING...' in order to avoid
# "LIC_FILES_CHKSUM points to an invalid file" error. This is because
# there is no ima-policy-1.0.tar.gz source bundle (which we do not really
# need), COPYING file is stored in files directory, and as any other patches
# and additional files in build directory, is stored one dir above
# update-ld-cache_1.0 directory (which in this case is empty).
LIC_FILES_CHKSUM = "file://../COPYING;md5=9741c346eef56131163e13b9db1241b3"

# Where to find source code for this package.
SRC_URI = "file://COPYING"
SRC_URI += "file://update-ld-cache"

do_install() {

    # Install required files.
    install -m 0755 ${WORKDIR}/update-ld-cache -D ${D}${exec_prefix}/sbin/update-ld-cache
}
