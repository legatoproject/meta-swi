# meta-openembedded/meta-oe is on BBPATH, and we are using
# require, because build should fail if file does not exist.
# At the present time, fakeroot in meta-openembedded is
# older (1.18.4) and recipe from current directory is used,
# but that may not be the case in the future.
# If meta-openembedded is upgraded, we do not have to change
# anything here, because paths would stay the same, and only
# recipe pick location would change (e.g. meta-openembedded
# one would be used if newer).
require recipes-core/fakeroot/fakeroot_${PV}.bb
require fakeroot.inc

SUMMARY = ""
DESCRIPTION = "${nativesdk-fakeroot}"
DEPENDS = ""
PROVIDES += "nativesdk-fakeroot"

inherit nativesdk

EXTRA_OECONF = "--program-prefix="

S = "${WORKDIR}/fakeroot-${PV}"

# Fix "QA Issue: -dev package contains non-symlink .so"
FILES_SOLIBSDEV = ""
FILES_${PN} += "${libdir}/*.so"

# Add only DEPENDS here, RDEPENDS will come from
# fakeroot_${PV}.bb .
DEPENDS = "nativesdk-libcap nativesdk-linux-libc-headers"

# Compatability for the rare systems not using or having SYSV
python () {
    if d.getVar('HOST_NONSYSV', True) and d.getVar('HOST_NONSYSV', True) != '0':
        d.setVar('EXTRA_OECONF', ' --with-ipc=tcp --program-prefix= ')
}
