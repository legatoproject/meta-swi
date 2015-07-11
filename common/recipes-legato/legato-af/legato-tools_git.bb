inherit native

DESCRIPTION = "Legato - Tools"
SECTION = "base"
DEPENDS = ""
PR = "r0"

require legato.inc

do_configure[noexec] = "1"

do_compile() {
    if grep 'sdk:' Makefile; then
        VERBOSE=1 make sdk
    else
        VERBOSE=1 make tools
    fi
}

do_install() {
    if grep 'sdk:' Makefile; then
        install -d ${D}${bindir}
        cd $(dirname ${D}${bindir})
        tar jxvf ${S}/releases/legato-tools-$(uname -m).tar.bz2
    else
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
    fi
}
