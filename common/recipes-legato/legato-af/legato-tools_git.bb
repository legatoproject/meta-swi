DESCRIPTION = "Legato - Tools"
SECTION = "base"
DEPENDS = ""
PR = "r0"

BBCLASSEXTEND = "native nativesdk"

require legato.inc

do_configure[noexec] = "1"

do_compile() {
    cd "${S}"
    VERBOSE=1 oe_runmake sdk
}

do_install() {
    install -d ${D}${bindir}
    cd $(dirname ${D}${bindir})
    tar jxvf ${S}/releases/legato-tools-$(uname -m).tar.bz2 --exclude="bin/ima-*"
}

