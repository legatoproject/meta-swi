inherit native
SUMMARY = "Yet Another Flash File System"

DESCRIPTION = "Tools for managing 'yaffs2' file systems."

SECTION = "base"
HOMEPAGE = "http://www.yaffs.net"
LICENSE = "GPLv2"

DEPENDS = "mtd-utils"
PROVIDES = "yaffs2-utils-native"
S = "${WORKDIR}/yaffs2"

# Source is the HEAD of aleph1-release-branch at the time of writing this recipe
SRC_URI = "file://yaffs2.tar.bz2 \
          "
SRCREV = "7862c133d9d887fc9a939aefd69ed3403c287d54"

LIC_FILES_CHKSUM = "file://utils/mkyaffs2image.c;beginline=12;endline=14;md5=a8fbab03ee852b7496ca20a8a763ecf3"

CFLAGS += "-I.. -DCONFIG_YAFFS_UTIL -DCONFIG_YAFFS_DOES_ECC"

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
