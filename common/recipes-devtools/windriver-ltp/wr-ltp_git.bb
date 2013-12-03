#
# Copyright (C) 2012 Wind River Systems, Inc.
#
SUMMARY = "Linux Test Project"
DESCRIPTION = "The Linux Test Project is a joint project with SGI, IBM, OSDL, \
and Bull with a goal to deliver test suites to the open source community that \
validate the reliability, robustness, and stability of Linux. The Linux Test \
Project is a collection of tools for testing the Linux kernel and related \
features."
HOMEPAGE = "http://ltp.sourceforge.net"
SECTION = "console/utils"

LICENSE = "GPLv2 & GPLv2+ & LGPLv2+ & LGPLv2.1+ & BSD-2-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

SRCREV = "619d8625898a9ca8572e6da0f28875c9eb09d37c"
PR = "r8"

# we have a few python scripts and need a little more
# than just python-core
#
RDEPENDS_${PN} = "ltp-testsuite open-posix-testsuite python python-textutils binutils-symlinks"

DEPENDS = "libaio"
DEPENDS_append_x86-64 += "numactl"
DEPENDS_append_x86 += "numactl"

SRC_URI = "git://github.com/linux-test-project/ltp.git;protocol=git \
           file://README \
           file://0001-add-wrLinux_ltp.patch \
           file://0002-add-wrLinux_posix.patch \
           file://0004-POSIX-remove-skiptest-file-and-update-wr-runposix.patch \
           file://0005-LTP-update-skiptest-file-and-wr-runltp.patch \
           file://0006-Update-of-test-knowledge-in-LTP-and-POSIX.patch \
           file://0008-Update-wr-runltp-and-test-knowledge-in-LTP-and-POSIX.patch \
           file://0009-Add-stress-test-case-to-default-skipped-test-list.patch \
           file://0010-wr-runltp-and-wr-runposix-update.patch \
           file://0011-POSIX-Add-skip-reason-knowledge-base-for-preempt_rt-kernel.patch \
           file://0012-LTP-add-fail-reason-for-cpuhotplug-test.patch \
           file://0013-LTP-add-thp03-fail-reason-to-test-knowledge-base.patch \
           file://0014-LTP-update-fail-reason-for-overcommit_memory02.patch \
           file://0015-LTP-add-fail-reason-for-readahead02.patch \
           file://0016-LTP-rename-kernel-type-preempt_rt-to-preempt-rt.patch \
	   file://0017-LTP-add-lib-Makefile-patch-for-realtime-test-suite.patch \
           file://0018-LTP-update-wr-runltp-and-wr-posix.patch \
           file://0019-Add-POSIX-fail-reason-for-timer_create-test.patch \
           file://0020-Add-profil01-to-LTP-test-skip-knowledge-base.patch \
           file://0021-Fix-the-case-match-string-in-wr-runltp.patch \
           file://0022-Add-LTP-and-POSIX-failure-reason-for-cgl-platform.patch \
           file://0023-Update-wr-runposix-to-filter-failure-reason-in-cgl-platform.patch \
           file://0024-Add-LTP-case-signalfd01-failure-reason-for-MIPS.patch \
           file://0025-Change-the-POSIX-install-folder-to-opt-open_posix_testsuite.patch \
           file://0026-Remove-sub-case-ftrace_tracing_enabled.sh-from-LTP-test.patch \
           file://0027-Add-failure-reason-for-LTP-test-case-fallocate01-in-MIPS.patch \
           file://0028-Fix-short-of-nodemask-array.patch \
           file://0029-Add-failure-reason-for-LTP-case-migrate_pages02.patch \
           file://0030-Fix-POSIX-mmap-5-1-failure-in-cgl-platform.patch \
           file://0031-Fix-uninitialized-access-to-nmask-array.patch \
           file://0032-Fix-the-logic-of-setting-nmask.patch \
          "
S = "${WORKDIR}/git"

export prefix = "/opt/ltp"
export exec_prefix = "/opt/ltp"

inherit autotools

PACKAGES += "open-posix-testsuite"
PACKAGES += "ltp-testsuite"
FILES_open-posix-testsuite += "/opt/open_posix_testsuite/"
FILES_ltp-testsuite += "/opt/ltp/"

TARGET_CC_ARCH += "${LDFLAGS}"

EXTRA_OECONF = "--with-power-management-testsuite=yes --with-realtime-testsuite=yes"

do_compile () {
	oe_runmake
	cd ${S}/testcases/open_posix_testsuite/
	oe_runmake generate-makefiles
	oe_runmake conformance-all
	oe_runmake tools-all
}

do_install(){
	install -d ${D}/opt/ltp
	oe_runmake DESTDIR=${D} SKIP_IDCHECK=1 install

	# Install Posix Test Suite
	install -d ${D}/opt/open_posix_testsuite
	export prefix="/opt/open_posix_testsuite/"
	export exec_prefix="/opt/open_posix_testsuite/"
	cd ${S}/testcases/open_posix_testsuite/
	oe_runmake DESTDIR=${D} SKIP_IDCHECK=1 install

	# Install wrLinux_posix
	cp ${WORKDIR}/README ${S}/testcases/open_posix_testsuite/wrLinux_posix/
	cp -r ${S}/testcases/open_posix_testsuite/wrLinux_posix ${D}/opt/open_posix_testsuite/
	install -m 755 ${S}/testcases/open_posix_testsuite/wrLinux_posix/wr-runposix ${D}/opt/open_posix_testsuite/wrLinux_posix/
	install -m 755 ${S}/testcases/open_posix_testsuite/wrLinux_posix/wr-runposix.install ${D}/opt/open_posix_testsuite/wrLinux_posix/
	${D}/opt/open_posix_testsuite/wrLinux_posix/wr-runposix.install

        # Install wrLinux_ltp
	cp ${WORKDIR}/README ${S}/wrLinux_ltp/
	cp -r ${S}/wrLinux_ltp ${D}/opt/ltp/
	install -m 755 ${S}/wrLinux_ltp/wr-runltp ${D}/opt/ltp/wrLinux_ltp/
}

# Avoid generated binaries stripping. Otherwise some of the ltp tests such as ldd01 & nm01 fails
INHIBIT_PACKAGE_STRIP = "1"


