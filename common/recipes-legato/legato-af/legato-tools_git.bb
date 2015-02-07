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

    cd ${D}${bindir}
    ln -sf mk mkif
    ln -sf mk mkcomp
    ln -sf mk mkexe
    ln -sf mk mkapp
    ln -sf mk mksys
    ln -sf mk mkdoc

    install -m 0755 ${S}/framework/tools/ifgen/ifgen ${D}${bindir}/
    for file in $(find ${S}/framework/tools/ifgen -name "*.py"); do
        install $file ${D}${bindir}/
    done
}
