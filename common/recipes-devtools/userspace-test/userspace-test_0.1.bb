DESCRIPTION = "userspace tests"
LIC_FILES_CHKSUM = "file://spidev_test.c;beginline=1;endline=12;md5=5f6a6ca88bef579b2b82d58218f9ee3a"
LICENSE = "GPLv2+"

inherit autotools

PR = "r0"
PV = "0.1"

DEPENDS = "gdb-cross i2c-tools"

SRC_URI = "file://spidev_test.c \
	   file://i2cdev_test.c \
	   file://sierra_spidev_test.c \
	   file://sierra_i2cdev_test.c \
	   file://keypad_test.c \
	   file://hello.c \
	   file://mem_leak.c \
	   file://vodafone \
	   file://vodafone.chat \
	   file://peer-china-unicom \
	   file://china-unicom "

S = "${WORKDIR}"

do_compile () {
        ${CC} -o spidev_test  spidev_test.c
        ${CC} -I ${STAGING_DIR_HOST}/usr/src/kernel/include -o sierra_spidev_test  sierra_spidev_test.c
        ${CC} -o i2cdev_test  i2cdev_test.c
        ${CC} -o sierra_i2cdev_test  sierra_i2cdev_test.c
        ${CC} -o keypad_test  keypad_test.c
        ${CC} -g -o hello     hello.c
        ${CC} -o mem_leak     mem_leak.c
}


do_install () {
        install -d ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/spidev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/sierra_spidev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/i2cdev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/sierra_i2cdev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/keypad_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/hello ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/mem_leak ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/vodafone ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/vodafone.chat ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/peer-china-unicom ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/china-unicom ${D}/opt/userspace-test
}

FILES_${PN} += "/opt/userspace-test/*" 
FILES_${PN}_dbg += "/opt/userspace-test/.debug" 

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
