DESCRIPTION = "Tools to create CWE tools from the Yocto build"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://COPYING;md5=9741c346eef56131163e13b9db1241b3"
SECTION = "base"
DEPENDS = ""
PR = "r0"

BBCLASSEXTEND = "native nativesdk"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "file://cwezip.cpp"
SRC_URI += "file://fotapkghdrcat.cpp"
SRC_URI += "file://hdrcnv.cpp"
SRC_URI += "file://Makefile"
SRC_URI += "file://makefota"
SRC_URI += "file://README_CWE.txt"
SRC_URI += "file://yoctocwetool.sh"
SRC_URI += "file://COPYING"
SRC_URI += "file://partition_update.py"
SRC_URI += "file://yocto_partition_update_cwe.sh"
SRC_URI += "file://splitboot.c"

S = "${WORKDIR}/"

DEPENDS += "zlib"

do_configure[noexec] = "1"

do_compile() {
    make all
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 fotapkghdrcat ${D}${bindir}
    install -m 0755 hdrcnv ${D}${bindir}
    install -m 0755 cwezip ${D}${bindir}
    install -m 0755 yoctocwetool.sh ${D}${bindir}
    install -m 0755 makefota ${D}${bindir}
    install -m 0644 README_CWE.txt ${D}${bindir}
    install -m 0755 partition_update.py ${D}${bindir}
    install -m 0755 yocto_partition_update_cwe.sh ${D}${bindir}
    install -m 0755 splitboot ${D}${bindir}
}

