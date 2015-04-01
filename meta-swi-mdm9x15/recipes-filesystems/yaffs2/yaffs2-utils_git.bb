SUMMARY = "Yet Another Flash File System"
DESCRIPTION = "Tools for managing 'yaffs2' file systems."

SECTION = "base"
HOMEPAGE = "http://www.yaffs.net"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://utils/mkyaffs2image.c;beginline=12;endline=14;md5=a8fbab03ee852b7496ca20a8a763ecf3"

PV = "0.0+git${SRCPV}"

DEPENDS = "mtd-utils"

SRC_URI = "git://codeaurora.org/platform/external/yaffs2;tag=M9615AAAARNLZA1611263;branch=penguin \
           file://0001-Dummy-required-android_filesystem_config.h.patch"
S = "${WORKDIR}/git/yaffs2"


CFLAGS_append = " -I.. -DCONFIG_YAFFS_UTIL -DCONFIG_YAFFS_DOES_ECC"

do_compile() {
    cd utils && oe_runmake
}

INSTALL_FILES = "mkyaffsimage \
                 mkyaffs2image \
                "
do_install() {
    install -d ${D}${sbindir}/
    for i in ${INSTALL_FILES}; do
        install -m 0755 utils/$i ${D}${sbindir}/
    done
}

BBCLASSEXTEND = "native nativesdk"

