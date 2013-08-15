DESCRIPTION = "Little Kernel bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
HOMEPAGE = "https://www.codeaurora.org/gitweb/quic/la?p=kernel/lk.git"
PROVIDES = "virtual/lk"

PR = "r0"

SRC_URI = "file://lk.tar.gz \
          "
S = "${WORKDIR}/${PN}"

MY_TARGET = "mdm9615"

EXTRA_OEMAKE = "TOOLCHAIN_PREFIX='${TARGET_PREFIX}' ${MY_TARGET}"

do_install() {
	install	-d ${D}/boot
	install build-${MY_TARGET}/appsboot.{mbn,raw} ${D}/boot
}

FILES_${PN} = "/boot"

do_deploy () {
        install -d ${DEPLOY_DIR_IMAGE}
        install build-${MY_TARGET}/appsboot.{mbn,raw} ${DEPLOY_DIR_IMAGE}
}
do_deploy[dirs] = "${S}"
addtask deploy before do_package_stage after do_compile

PACKAGE_STRIP = "no"
