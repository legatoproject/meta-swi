inherit autotools gettext
SUMMARY = "XML Parser library "
HOMEPAGE = "https://github.com/zeux/pugixml"
LICENSE = "MIT"
PRIORITY = "optional"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Package Revision (update whenever recipe is changed)
PR = "r0"

TARGET_CC_ARCH += "${LDFLAGS}"

SRC_URI = "https://github.com/zeux/pugixml/archive/v${PV}.zip;name=pugixml-v1.4.zip \
           file://001_Makefile.patch \
"

SRC_URI[pugixml-v1.4.zip.md5sum] = "151031939797d89c034dc0be55ba8943"
SRC_URI[pugixml-v1.4.zip.sha256sum] = "19f7f5c833175105000196620b573a55747b8866a00218534b445c78a272277c"

S = "${WORKDIR}/${PN}-${PV}"

inherit autotools pkgconfig

rm_makefile() {
    rm ${S}/Makefile
}

do_patch[postfuncs] += "rm_makefile"

do_compile () {
    oe_runmake
    rm -f *.o
}
