SRCREV = "${AUTOREV}"
LK_REPO ?= "git://github.com/legatoproject/lk.git;protocol=https;branch=mdm9x40-swi"

LK_TARGET = "mdm9640"

EXTRA_OEMAKE += "LINUX_KERNEL_DIR='${LINUX_REPO_DIR}/..'"

do_tag_lk() {
	# We remove the sierra_lkversion.h to avoid this file to be counted in sha1
	( cd ${S}; \
		echo "#define LKVERSION  \"${PV}_"`for file in $(find -type f -not -regex '.*\(pc\|git\|build-\|patches\).*'); do \
		sha256sum $file; done | \
		sort | grep -v sierra_lkversion.h | awk '{print $1}' | sha256sum | cut -c 1-10 -`"\"" ) >${S}/app/aboot/sierra_lkversion.h
}

addtask tag_lk before do_compile after do_configure

do_install() {
    install -d ${D}/boot
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${D}/boot
}

do_deploy() {
    install -d ${DEPLOY_DIR_IMAGE}
    install ${B}/build-${LK_TARGET}/appsboot.mbn ${DEPLOY_DIR_IMAGE}
}
