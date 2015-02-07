DESCRIPTION = "Legato - Application framework"
SECTION = "base"
DEPENDS = "legato-tools"
PR = "r0"

inherit legato

require legato.inc

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

libdir = "/usr/local/lib"

LDFLAGS = ""
TARGET_LDFLAGS = ""

do_configure[noexec] = "1"

do_prepare_tools[depends] = "legato-tools:do_populate_sysroot"
do_prepare_tools() {
    # Remove 'tools' target
    sed -i 's/.PHONY: tools//g' ${S}/Makefile
    sed -i 's/tools:/disabled_tools:/g' ${S}/Makefile
    touch ${S}/tools

    # Prepare bin/
    mkdir -p ${S}/bin
    cd ${S}

    realmk=$(which mk)
    echo "mk: $realmk"

    cd ${S}/bin
    ln -sf $realmk mk
    ln -sf mk mkif
    ln -sf mk mkcomp
    ln -sf mk mkexe
    ln -sf mk mkapp
    ln -sf mk mksys
    ln -sf ${S}/framework/tools/scripts/* ./
    ln -sf ${S}/framework/tools/ifgen/ifgen ifgen
}

addtask prepare_tools before do_compile after do_unpack

compile_target() {
    make $LEGATO_TARGET
}

do_compile_prepend() {
    # For some reason this doesn't work in do_unpack_append
    # Need to grab the airvantage module if it isn't there already
    if [ ! -f "${S}/airvantage/CMakeLists.txt" ]
    then
        git submodule init
        git submodule update
    fi
}

do_install() {
    install -d ${D}/opt/legato

    # version file
    install ${S}/version ${D}/opt/legato/
    LEGATO_VERSION=$(cat ${S}/version)

    # start-up scripts
    install -d ${D}/opt/legato/startupDefaults
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        for script in $(find ${S}/build/$target/staging/mnt/flash/startupDefaults -type f); do
            install $script ${D}/opt/legato/startupDefaults/
        done
    done

    # headers
    install -d ${D}${includedir}
    for file in $(find ${S}/framework/c/inc -type f); do
        echo "Installing header: $file"
        install $file ${D}${includedir}
    done

    # private headers required by _main.c
    install -d ${D}/usr/share/legato/src
    cd ${S}/framework/c/src
    for file in eventLoop.h log.h args.h; do
        install $file ${D}/usr/share/legato/src/
    done

    # liblegato
    install -d ${D}${libdir}
    install ${S}/build/$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')/bin/lib/liblegato.so ${D}${libdir}/liblegato.so

    # API files
    install -d ${D}/usr/share/legato/interfaces
    cd ${S}
    for file in $(find ./interfaces -name "*.api"); do
        dir=$(dirname $file)
        echo "Installing API: $file"
        if [[ "$dir" != "." ]]; then
            install -d ${D}/usr/share/legato/$dir
        fi
        install $file ${D}/usr/share/legato/$file
    done
}

do_install_image() {
    # legato-image
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        mkdir -p ${LEGATO_STAGING_DIR}/${target}
        cp -R ${S}/build/${target}/staging/* ${LEGATO_STAGING_DIR}/${target}/
    done
}

FILES_${PN}-dbg += "usr/local/bin/.debug/*"
FILES_${PN}-dbg += "usr/local/lib/.debug/*"

FILES_${PN}-dev += "usr/local/lib/libjansson.so"
FILES_${PN}-dev += "usr/local/lib/libjansson.so.4"

FILES_${PN} += "opt/legato/*"
FILES_${PN} += "usr/local/*"
FILES_${PN} += "mnt/legato/*"

INSANE_SKIP_${PN} = "installed-vs-shipped"
