DESCRIPTION = "Sierra Wireless Key Query"

HOMEPAGE = "http://www.sierrawireless.com"

LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://../sierra_ks_if_user_test.c;beginline=7;endline=7;md5=95e2478959b59899b9b8fcbd9c5b89e8"

SRC_URI = "file://sierra_ks_if_user_test.c \
           file://sierra_ks_if_dmv_test.c \
           file://sierra_ks_if_intf.h \
          "

do_configure[noexec] = "1"

DEPENDS += "i2c-tools"
DEPENDS += "linux-quic"

TARGET_LDFLAGS_prepend = " -li2c "

do_compile() {
    cp -pv ${WORKDIR}/sierra_ks_if_dmv_test.c .
    cp -pv ${WORKDIR}/sierra_ks_if_user_test.c .
    cp -pv ${WORKDIR}/sierra_ks_if_intf.h .
    oe_runmake sierra_ks_if_user_test
    oe_runmake sierra_ks_if_dmv_test
}

do_install() {
    install -m 0755 sierra_ks_if_user_test -D ${D}/usr/bin/kstest
    install -m 0755 sierra_ks_if_dmv_test -D ${D}/usr/bin/kskey
}
