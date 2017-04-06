DESCRIPTION = "Concise Binary Object Representation (CBOR) Library"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "86c81867754e19cba69efab74c73f045eb133349"
TINYCBOR_REPO = "git://github.com/01org/tinycbor.git;branch=master"

SRC_URI  = "${TINYCBOR_REPO};protocol=https"
SRC_URI[md5sum] = "e0dddd1b97185cd5827edc03ef76dd32"
SRC_URI[sha256sum] = "b1e5239a6aa7997cc226554db46fb48eff6358a1bd16ca3294478056f2a2408f"
SRC_URI += "file://0001-tinycbor.patch"

# tinycbor library major and minor versions.
LIBMAJOR = "0"
LIBMINOR = "2"

# Package revision and package version.
PR = "r0"
PV = "${LIBMAJOR}.${LIBMINOR}"

# Where are the sorces.
S = "${WORKDIR}/git"

# Where binaries are going to be.
B = "${S}"

# Typing this number of times is not fun at all.
localdir = "/usr/local"

# Build as position-independent code as to be able to work as dynamic library
TARGET_CFLAGS="-Wall -Wextra -fPIC"

# Compile tinycbor
do_compile() {
    oe_runmake all
}

# Install tinycbor to location forced by its Makefile.
do_install() {
    DESTDIR=${D} make install
}

# Do cleanup before final installation, and make sure that library is installed
# in standard location (e.g. searchable by dynamic linker).
do_install_append() {

    # Fix libraries
    install -d ${D}/${libdir}
    cd ${D}/${localdir}/lib
    rm -f libtinycbor.so ; ln -s libtinycbor.so.${PV} libtinycbor.so
    rm -f libtinycbor.so.${LIBMAJOR} ; ln -s libtinycbor.so.${PV} \
        libtinycbor.so.${LIBMAJOR}
    mv ${D}/${localdir}/lib/* ${D}/${libdir}

    # Fix binaries
    install -d ${D}/${bindir}
    install -m 755 ${D}/${localdir}/bin/* ${D}/${bindir}

    # Fix header files.
    install -d ${D}/${includedir}/tinycbor
    install -m 644 ${D}/${localdir}/include/tinycbor/*.h \
        ${D}/${includedir}/tinycbor

    # Delete stuff we do not need
    rm -rf ${D}/${libdir}/{libtinycbor.a,pkgconfig}
    rm -rf ${D}/${localdir}
}

do_populate_sysroot() {

    # Install required libraries. We'll be using dynamic one instead of default
    # static. If needed, we could easily install static one as well.
    install -d ${SYSROOT_DESTDIR}/${libdir}
    install -m 0644 ${D}/${libdir}/libtinycbor.so.0.2 \
        ${SYSROOT_DESTDIR}/${libdir}/libtinycbor.so.0.2
    cd ${SYSROOT_DESTDIR}/${libdir}
    ln -s libtinycbor.so.0.2 libtinycbor.so
    ln -s libtinycbor.so.0.2 libtinycbor.so.${LIBMAJOR}

    # Install required header files.
    install -d ${SYSROOT_DESTDIR}/${includedir}/tinycbor
    install -m 0644 ${D}/${includedir}/tinycbor/*.h \
        ${SYSROOT_DESTDIR}/${includedir}/tinycbor
}

