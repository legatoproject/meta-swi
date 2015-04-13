DESCRIPTION = "userspace tests"
LIC_FILES_CHKSUM = "file://spidev_test.c;beginline=1;endline=12;md5=5f6a6ca88bef579b2b82d58218f9ee3a"
LICENSE = "GPLv2+"

inherit autotools

PR = "r0"
PV = "0.1"

DEPENDS = "gdb-cross i2c-tools"

SRC_URI = "file://${BPN}-${PV}/"


do_compile () {
        ${CC} -o spidev_test  spidev_test.c
        ${CC} -I ${STAGING_DIR_HOST}/usr/src/kernel/include -o sierra_spidev_test  sierra_spidev_test.c
        ${CC} -o i2cdev_test  i2cdev_test.c
        ${CC} -I ${STAGING_DIR_HOST}/usr/src/kernel/include -o sierra_i2cdev_test  sierra_i2cdev_test.c
        ${CC} -o keypad_test  keypad_test.c
        ${CC} -g -o hello     hello.c
        ${CC} -o mem_leak     mem_leak.c
        ${CC} -o tty_dev_test     tty_dev_test.c
        ${CC} -o read    -lpthread -Wall -g read.c
        ${CC} -o writeread   -lpthread -Wall -g  writeread.c
}


do_install () {
        install -d ${D}/opt/userspace-test
        install -m 0644 ${S}/vodafone ${D}/opt/userspace-test
        install -m 0644 ${S}/vodafone.chat ${D}/opt/userspace-test
        install -m 0644 ${S}/peer-china-unicom ${D}/opt/userspace-test
        install -m 0644 ${S}/china-unicom ${D}/opt/userspace-test
        find ${S}/ -executable -type f -exec cp {} ${D}/opt/${BPN}/ \;
}

FILES_${PN} += "/opt/userspace-test/*" 
FILES_${PN}_dbg += "/opt/userspace-test/.debug" 

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
