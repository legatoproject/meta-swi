DESCRIPTION = "userspace tests"
LIC_FILES_CHKSUM = "file://spidev_test.c;md5=5d1188f6d90e425ad7557cd14d35dfc9"
LICENSE = "GPLv2+"

inherit autotools

PR = "r0"
PV = "0.1"

DEPENDS = "gdb-cross i2c-tools"

SRC_URI = "file://spidev_test.c \
	   file://i2cdev_test.c \
	   file://keypad_test.c \
	   file://hello.c \
	   file://mem_leak.c \
	   file://peer-china-unicom \
	   file://china-unicom "

S = "${WORKDIR}"

do_compile () {
        ${CC} -o spidev_test  spidev_test.c
        ${CC} -o i2cdev_test  i2cdev_test.c
        ${CC} -o keypad_test  keypad_test.c
        ${CC} -g -o hello     hello.c
        ${CC} -o mem_leak     mem_leak.c
}


do_install () {
        install -d ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/spidev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/i2cdev_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/keypad_test ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/hello ${D}/opt/userspace-test
        install -m 0755 ${WORKDIR}/mem_leak ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/peer-china-unicom ${D}/opt/userspace-test
        install -m 0644 ${WORKDIR}/china-unicom ${D}/opt/userspace-test
}

FILES_${PN} += "/opt/userspace-test/*" 
FILES_${PN}_dbg += "/opt/userspace-test/.debug" 
