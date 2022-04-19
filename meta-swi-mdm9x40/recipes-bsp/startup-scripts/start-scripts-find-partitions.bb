DESCRIPTION = "Start up script for detecting partitions"
HOMEPAGE = "http://codeaurora.org"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=550794465ba0ec5312d6919e203a55f9"

SRC_URI +="file://find_partitions.sh"

PR = "r3"

inherit update-rc.d

INITSCRIPT_NAME = "find_partitions.sh"
INITSCRIPT_PARAMS = "start 08 S ."

do_install() {
    install -m 0755 ${WORKDIR}/find_partitions.sh -D ${D}${sysconfdir}/init.d/find_partitions.sh
}

