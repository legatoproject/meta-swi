DESCRIPTION = "Little Kernel bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
HOMEPAGE = "https://www.codeaurora.org/gitweb/quic/la?p=kernel/lk.git"
PROVIDES = "virtual/lk"

PR = "r0"

SRC_URI = "file://lk.tar.gz"
SRC_URI += "file://0002-TRAC-1223-lk-make_sure_that_Yocto_kernel_receives_correct_atag_MTD_partition_information_from_bootloader.patch"
SRC_URI += "file://0003-SBM-14659-Modem-cannot-bootup-after-flash-customer-Yocto-image-with-fastboot.patch"
SRC_URI += "file://0004-SBM-15385-GPIO-cooperation-mode-support.patch"
SRC_URI += "file://0005-SBM-15691-support-squashfs-download.patch"

S = "${WORKDIR}/${PN}"

MY_TARGET = "mdm9615"

EXTRA_OEMAKE = "TOOLCHAIN_PREFIX='${TARGET_PREFIX}' ${MY_TARGET}"

do_install() {
	install	-d ${D}/boot
	install ${S}/build-${MY_TARGET}/appsboot.mbn ${D}/boot
	install ${S}/build-${MY_TARGET}/appsboot.raw ${D}/boot
}

FILES_${PN} = "/boot"

do_deploy () {
	install -d ${DEPLOY_DIR_IMAGE}
	install ${S}/build-${MY_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
	install ${S}/build-${MY_TARGET}/appsboot.raw ${DEPLOY_DIR_IMAGE}
}
do_deploy[dirs] = "${S}"
addtask deploy before do_package_stage after do_compile

PACKAGE_STRIP = "no"
