DESCRIPTION = "Legato - startupGPIO"
SECTION = "base"
PR = "r0"

HOMEPAGE = "http://www.sierrawireless.com/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

LEGATO_APP_NAME = "startupGpio"

LEGATO_APP_VER = "1.0"

SRC_URI = "file://startupGpio/startupGpio.adef"
SRC_URI += "file://startupGpioComponent/Component.cdef"
SRC_URI += "file://startupGpioComponent/startupGpio.c"

S = "${WORKDIR}"

inherit legato

compile_target() {
   cd ${S}/${LEGATO_APP_NAME}

   mkapp -v \
      -t ${LEGATO_TARGET} \
      -i ${LEGATO_ROOT} \
      -i ${LEGATO_ROOT}/interfaces \
      -i ${LEGATO_ROOT}/c/inc \
      -s ${S} \
      ${LEGATO_APP_NAME}.adef \
      --append-to-version=${LEGATO_APP_VER}
}

do_install:prepend() {
    # Copy the legato files in the good folder for do_install
    cp -pv ${WORKDIR}/${LEGATO_APP_NAME}/${LEGATO_APP_NAME}.* ${S}
}

