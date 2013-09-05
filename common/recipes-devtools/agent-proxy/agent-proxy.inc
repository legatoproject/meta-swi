#
# Copyright (C) 2012 Wind River Systems, Inc.
#
SUMMARY = "Proxy for UDP/TCP debug connections"
DESCRIPTION = "The agent-proxy will forward tcp or udp connections as well as allow for script multiplexing of terminal sessions."
HOMEPAGE = "http://kgdb.wiki.kernel.org/jjj"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb723b61539feef013de476e68b5c50a"

SECTION = "devel"

INC_PR = "r0"

EXTRA_OEMAKE = "'CC=${CC}'"

SRCREV = "e6c9d3d996bd55e7ab14dbd74deb7841e0c3a4f1"
PV = "1.96+git${SRCPV}"

SRC_URI += "git://git.kernel.org/pub/scm/utils/kernel/kgdb/agent-proxy.git;protocol=git"

BBCLASSEXTEND = "native nativesdk"

S = "${WORKDIR}/git"

DEFAULT_PREFERENCE = "-1"

do_install () {
    install -d ${D}${bindir}
    install -m 0755 agent-proxy ${D}${bindir}
}
