inherit autotools-brokensep pkgconfig

DESCRIPTION = "Build Android liblog"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/system/core/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "f4d07fb7ca9244ace3bf1061388694846f740006"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/system/core;branch=le-blast.lnx.1.2"

PR = "r1"

SRC_URI  = "${SYSTEMCORE_REPO}"
SRC_URI  += "file://50-log.rules"

S = "${WORKDIR}/git/liblog"

BBCLASSEXTEND = "native"

EXTRA_OECONF  = " --with-core-includes=${WORKDIR}/git/include"
EXTRA_OECONF += " --disable-static"
EXTRA_OECONF_append_class-target = " --with-logd-logging"

do_install_append() {
    if [ "${CLASSOVERRIDE}" = "class-target" ]; then
       install -m 0644 -D ${WORKDIR}/50-log.rules ${D}${sysconfdir}/udev/rules.d/50-log.rules
    fi
}

PACKAGE_DEBUG_SPLIT_STYLE = 'debug-without-src'
FILES_${PN}-dbg = "${libdir}/.debug/* ${bindir}/.debug/*"
FILES_${PN}     = "${libdir}/pkgconfig/* ${libdir}/* ${sysconfdir}/*"
FILES_${PN}-dev = "${libdir}/*.so ${libdir}/*.la ${includedir}/*"

PROVIDES = "system-core-liblog"
RPROVIDES_${PN} = "system-core-liblog"
