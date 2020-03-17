DESCRIPTION = "Sierra Wireless Initialization of TI WL18XX wireless"

HOMEPAGE = "http://www.sierrawireless.com"

LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://../tiwifi.sh;startline=2;endline=2;md5=4ab7b147102bbb17e696589e8e19383e"

SRC_URI = "file://tiwifi.sh \
          "

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -m 0755 ${WORKDIR}/tiwifi.sh -D ${D}${sysconfdir}/init.d/tiwifi
}
