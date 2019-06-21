SUMMARY = "Userspace headers for Sierra Wireless defined drivers"
DESCRIPTION = "Adds userspace headers for SPI, I2C etc."
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://../sierra_i2cdev.h;beginline=5;endline=12;md5=23a89ddd6c0ee9b05d0c7463c7ff4cb5"
DEPENDS = "system-core"

PN = "sierra-dev-headers"
PR = "r0"

SRC_URI = " \
            file://sierra_i2cdev.h \
            file://sierra_spidev.h \
            "

S = "${WORKDIR}/sierra-dev-headers"

# Install all additional files/dirs
do_install_append() {
    # create include dirs
    install -m 0755 -d ${D}/usr/include/linux/spi/
    install -m 0755 -d ${D}/usr/include/linux/i2c/

    # add headers to rootfs
    install -m 0644 ${WORKDIR}/sierra_i2cdev.h -D ${D}/usr/include/linux/i2c/sierra_i2cdev.h
    install -m 0644 ${WORKDIR}/sierra_spidev.h -D ${D}/usr/include/linux/spi/sierra_spidev.h
}

# Add files/dirs that need to be put into this package
FILES_${PN} += " \
               /usr/include/linux/i2c/sierra_i2cdev.h \
               /usr/include/linux/spi/sierra_spidev.h \
               "

ALLOW_EMPTY_${PN} = "1"
