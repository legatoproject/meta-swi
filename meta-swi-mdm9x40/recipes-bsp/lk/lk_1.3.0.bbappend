SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x40-swi"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

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

do_install() {
    install -d ${D}/boot
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${D}/boot
    fi
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
    if [ -f "${B}/build-${LK_TARGET}/appsboot_rw.mbn" ] ; then
        install ${B}/build-${LK_TARGET}/appsboot_rw.mbn ${DEPLOY_DIR_IMAGE}
    fi
    cp ${B}/build-${LK_TARGET}/lkversion ${DEPLOY_DIR_IMAGE}/lk.version
}
