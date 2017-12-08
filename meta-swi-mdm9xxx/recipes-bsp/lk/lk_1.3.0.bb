DESCRIPTION = "Little Kernel bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/kernel/lk"
PROVIDES = "virtual/lk"

PR = "r2"

SRC_URI = "${LK_REPO}"

S = "${WORKDIR}/git"

B = "${WORKDIR}/build"

LK_TARGET ?= "mdm9615"

# Debug levels you could have. Default is critical.
# 0 - CRITICAL
# 1 - INFO
# 2 - SPEW
LK_DEBUG ?= "0"

EXTRA_OEMAKE = "TOOLCHAIN_PREFIX='${TARGET_PREFIX}' TOOLCHAIN_OPTIONS='${TOOLCHAIN_OPTIONS}' ${LK_TARGET} DEBUG=${LK_DEBUG} BOOTLOADER_OUT='${B}'"

do_tag_lk() {
	# We remove the sierra_lkversion.h to avoid this file to be counted in sha1
	( cd ${S}; \
		LK_VERSION="${PV}_"`for file in $(find -type f -not -regex '.*\(pc\|git\|build-\|patches\).*'); do \
			sha256sum $file; done | \
			sort | grep -v sierra_lkversion.h | awk '{print $1}' | sha256sum | cut -c 1-10 -`""
		echo "#define LKVERSION  \"${LK_VERSION}\"" > ${S}/app/aboot/sierra_lkversion.h
		mkdir -p ${B}/build-${LK_TARGET}
		echo "${LK_VERSION} $(date +'%Y/%m/%d %H:%M:%S')" >> ${B}/build-${LK_TARGET}/lkversion )
}

addtask tag_lk before do_compile after do_configure

do_compile[dirs] = "${S}"

do_install() {
	install -d ${D}/boot
	install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
	install ${B}/build-${LK_TARGET}/appsboot.raw ${D}/boot
}

FILES_${PN} = "/boot"

do_deploy() {
	install -d ${DEPLOY_DIR_IMAGE}
	install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
	install ${B}/build-${LK_TARGET}/appsboot.raw ${DEPLOY_DIR_IMAGE}
	if [ -f "${B}/build-${LK_TARGET}/lkversion" ] ; then
		cp ${B}/build-${LK_TARGET}/lkversion ${DEPLOY_DIR_IMAGE}/lk.version
	fi
}

do_deploy[dirs] = "${S}"
addtask deploy before do_package_stage after do_install

PACKAGE_STRIP = "no"

FILES_${PN} = "/boot"
FILES_${PN}-dbg = "/boot/.debug"
