DESCRIPTION = "Legato - ftp"
SECTION = "base"
PR = "r0"

HOMEPAGE = "http://www.sierrawireless.com/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

LEGATO_APP_NAME = "ftp"

LEGATO_APP_VER = "1.0"

DEPENDS = "legato-af"
DEPENDS +=  "curl"
RDEPENDS:${PN} =  "curl"
RDEPENDS:${PN} += "gnutls"
RDEPENDS:${PN} += "libtasn1"
RDEPENDS:${PN} += "zlib"
RDEPENDS:${PN} += "libgcrypt"

SRC_URI  = "file://ftp/ftp.adef"

SRC_URI += "file://ftp/ftpComponent/Component.cdef"
SRC_URI += "file://ftp/ftpComponent/ftp.c"

inherit legato

compile_target() {
    cd ${WORKDIR}/${LEGATO_APP_NAME}

    mkapp -v \
        -t ${LEGATO_TARGET} \
        -i ${LEGATO_ROOT} \
        -i ${LEGATO_ROOT}/interfaces/dataConnectionService \
        -i ${LEGATO_ROOT}/c/inc \
        -i ${WORKDIR}/${LEGATO_APP_NAME}/ftpComponent \
        -s {WORKDIR}/.. \
        ${LEGATO_APP_NAME}.adef \
        --append-to-version=${LEGATO_APP_VER} \
        --ldflags=-lcurl \
        --ldflags=-pthread
}

do_install:prepend() {
    # Copy the legato files in the good folder for do_install
    cp -pv ${WORKDIR}/${LEGATO_APP_NAME}/${LEGATO_APP_NAME}.* ${S}
}
