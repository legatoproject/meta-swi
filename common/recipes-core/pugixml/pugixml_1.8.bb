inherit autotools gettext
SUMMARY = "XML Parser library "
HOMEPAGE = "https://github.com/zeux/pugixml"
LICENSE = "MIT"
PRIORITY = "optional"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Package Revision (update whenever recipe is changed)
PR = "r0"

TARGET_CC_ARCH += "${LDFLAGS}"

SRC_URI = "https://github.com/zeux/pugixml/archive/v${PV}.zip;name=pugixml-v1.8.zip \
           file://001_Makefile.patch \
"

SRC_URI[pugixml-v1.8.zip.md5sum] = "5229b9f38f938ee935f32ac63328fa18"
SRC_URI[pugixml-v1.8.zip.sha256sum] = "2ee334c7e09c5d1f0db8ef0db71a8fad73a3ab838795bc9189b6194b5e194ffd"

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
