SUMMARY = "Debug Image init scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
PN = "initdbgscripts"
PR = "r0"

SRC_URI = "file://init.sh \
          "
S = "${WORKDIR}"

do_install() {
    install -m 0755 init.sh -D ${D}${bindir}/init.sh
}

