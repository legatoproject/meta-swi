inherit native

DESCRIPTION = "Legato - Tools"
SECTION = "base"
DEPENDS = ""
PR = "r0"

require legato.inc

do_configure[noexec] = "1"

do_compile() {
    VERBOSE=1 make tools
}

do_install() {
    install -d ${D}${bindir}
    for file in $(find ${S}/bin -name "mk"); do
        echo "Copying $file ..."
        install -m 0755 $file ${D}${bindir}/
    done
}
