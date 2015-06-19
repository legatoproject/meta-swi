DESCRIPTION = "Little Kernel bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/kernel/lk"
PROVIDES = "virtual/lk"

PR = "r2"

SRC_URI  = "git://codeaurora.org/kernel/lk;tag=M9615AAAARNLZA1713041;branch=ics_strawberry"
SRC_URI += "file://0000-mdm9x15-Import-SWI-changes.patch"
SRC_URI += "file://0002-TRAC-1223-lk-make_sure_that_Yocto_kernel_receives_correct_atag_MTD_partition_information_from_bootloader.patch"
SRC_URI += "file://0003-SBM-14659-Modem-cannot-bootup-after-flash-customer-Yocto-image-with-fastboot.patch"
SRC_URI += "file://0004-SBM-15385-GPIO-cooperation-mode-support.patch"
SRC_URI += "file://0005-SBM-15691-support-squashfs-download.patch"
SRC_URI += "file://0006-SBM-17249-support-ubi-download.patch"
SRC_URI += "file://0007-TRAC-2357-LK-version.patch"
SRC_URI += "file://0008-SBM-16707-lk-debug-msg-on-uart.patch"
SRC_URI += "file://0009-TRAC-2623-Provide-sysroot-to-gcc-and-ld.patch"
SRC_URI += "file://0010-TRAC-2797-WP85-support-and-fastboot-support-for-user1-partition.patch"

S = "${WORKDIR}/git"

LK_TARGET = "mdm9615"

# Debug levels you could have. Default is critical.
# 0 - CRITICAL
# 1 - INFO
# 2 - SPEW
LK_DEBUG ?= "0"

EXTRA_OEMAKE = "TOOLCHAIN_PREFIX='${TARGET_PREFIX}' ${LK_TARGET} DEBUG=${LK_DEBUG}"

do_tag_lk() {
	# We remove the sierra_lkversion.h to avoid this file to be counted in sha1
	( cd ${S}; \
		echo "#define LKVERSION  \"${PV}_"`for file in $(find -type f -not -regex '.*\(pc\|git\|build-\|patches\).*'); do \
		sha256sum $file; done | \
		sort | grep -v sierra_lkversion.h | awk '{print $1}' | sha256sum | cut -c 1-10 -`"\"" ) >${S}/app/aboot/sierra_lkversion.h
}

addtask tag_lk before do_compile after do_configure

do_install() {
	install	-d ${D}/boot
	install ${S}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
	install ${S}/build-${LK_TARGET}/appsboot.raw ${D}/boot
}

FILES_${PN} = "/boot"

do_deploy () {
	install -d ${DEPLOY_DIR_IMAGE}
	install ${S}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
	install ${S}/build-${LK_TARGET}/appsboot.raw ${DEPLOY_DIR_IMAGE}
}

do_deploy[dirs] = "${S}"
addtask deploy before do_package_stage after do_compile

PACKAGE_STRIP = "no"
