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
	echo "SRC_URI: ${SRC_URI}"
	echo "S: ${S}"
	echo "LEGATO_BUILD: ${LEGATO_BUILD}"
	echo "LEGATO_TARGET: ${LEGATO_TARGET}"
	echo "LEGATO_ROOT: ${LEGATO_ROOT}"
	echo "LEGATO_ROOTFS_TARGETS: ${LEGATO_ROOTFS_TARGETS}"
	echo "LEGATO_IMAGE: ${LEGATO_IMAGE}"
	echo "LEGATO_REPO: ${LEGATO_REPO}"
	echo "LEGATO_CHKSUM: ${LEGATO_CHKSUM}"
	echo "LEGATO_ARGS: ${LEGATO_ARGS}"
	echo "LEGATO_WRKDIR: ${LEGATO_WRKDIR}"
	echo "FW_VERSION: ${FW_VERSION}"
	echo "LEGATO_STAGING_DIR: ${LEGATO_STAGING_DIR}"
	echo "LEGATO_VERSION: ${LEGATO_VERSION}"

	cd ${S}/${LEGATO_APP_NAME}

	mkapp -v -t ${LEGATO_TARGET} -i ${LEGATO_ROOT} -i ${LEGATO_ROOT}/interfaces -i ${LEGATO_ROOT}/c/inc -s ${S} ${LEGATO_APP_NAME}.adef --append-to-version=${LEGATO_APP_VER}
	cp -p ${LEGATO_APP_NAME}.${LEGATO_TARGET} ${S}
}
