SUMMARY = "Inittab configuration for SysVinit"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

PR = "r10"

SRC_URI = "file://inittab"

S = "${WORKDIR}/sysvinit-${PV}"

INHIBIT_DEFAULT_DEPS = "1"

do_compile() {
	:
}

do_install_append() {
    sed -i 's/^ttyHSL1:/HSL1:/g' ${D}${sysconfdir}/inittab
}


