DESCRIPTION = "Legato - Modem Demo"
SECTION = "base"
PR = "r0"

HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

LIC_FILES_CHKSUM = "file://CMakeLists.txt;startline=2;endline=2;md5=a4e10fb5509b38e2c8b19b82d1d832f6"

# Default is to pull from github, Can be overridden in the build script
LEGATO_REPO ?= "git://github.com/legatoproject/legato-af.git;protocol=https;rev=master"
LEGATO_CHKSUM ?= "4e5d47c0504d0c2f7a032a6078d32a93cd8f583eee135ca4f6eeb00215c50563"

SRC_URI = "${LEGATO_REPO}"
SRC_URI[sha256sum] ?= "${LEGATO_CHKSUM}"

S = "${WORKDIR}/git/apps/sample/modemDemo"

LEGATO_APP_NAME = "modemDemo"

inherit legato

compile_target() {
    mkapp -v \
        -t $LEGATO_TARGET \
        -C "${CFLAGS}" \
        -i $LEGATO_ROOT/src \
        -i $LEGATO_ROOT/interfaces/modemServices/ \
        -i $LEGATO_ROOT/interfaces/dataConnectionService/ \
        ${LEGATO_APP_NAME}.adef
}
