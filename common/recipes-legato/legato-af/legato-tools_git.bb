# This recipe
inherit native

DESCRIPTION = "Legato - Tools"
SECTION = "base"
DEPENDS = ""
PR = "r0"

require legato.inc

do_configure[noexec] = "1"

do_compile() {
    cd "${LEGATO_WORKDIR}"
    VERBOSE=1 oe_runmake sdk
}

do_install() {
    install -d ${D}${bindir}
    cd $(dirname ${D}${bindir})
    tar jxvf ${S}/releases/legato-tools-$(uname -m).tar.bz2
}

