DESCRIPTION = "Legato - Application framework"
SECTION = "base"
DEPENDS = "legato-tools"
PR = "r0"

inherit legato

require legato.inc

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

LDFLAGS = ""
TARGET_LDFLAGS = ""

do_configure[noexec] = "1"

do_compile[depends] = "legato-tools:do_populate_sysroot"

compile_target() {
    make $LEGATO_TARGET
}

do_install() {
    libdir="/usr/local/lib"

    install -d ${D}/opt/legato

    # version file
    install ${B}/version ${D}/opt/legato/
    install -d ${D}/usr/share/legato/
    install ${B}/version ${D}/usr/share/legato/

    if [ -d "${B}/build/$target/staging/mnt/flash" ]; then
        # start-up scripts
        install -d ${D}/opt/legato/startupDefaults
        for target in ${LEGATO_ROOTFS_TARGETS}; do
            for script in $(find ${B}/build/$target/staging/mnt/flash/startupDefaults -type f); do
                install $script ${D}/opt/legato/startupDefaults/
            done
        done
    fi

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
    first_target=$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')
    if [ -e "${B}/build/$first_target/bin/lib/liblegato.so" ]; then
        install ${B}/build/$first_target/bin/lib/liblegato.so ${D}${libdir}/liblegato.so
    else
        install ${B}/build/$first_target/staging/system/lib/liblegato.so ${D}${libdir}/liblegato.so
    fi

    # Populate liblegato.so in sysroots/
    for target in $(echo ${LEGATO_ROOTFS_TARGETS}); do
        install -d ${D}/usr/share/legato/build/$target/framework/lib
        if [ -e "${B}/build/$target/bin/lib/liblegato.so" ]; then
            install ${B}/build/$target/bin/lib/liblegato.so \
                    ${D}/usr/share/legato/build/$target/framework/lib/liblegato.so
        else
            install ${B}/build/$target/staging/system/lib/liblegato.so \
                    ${D}/usr/share/legato/build/$target/framework/lib/liblegato.so
        fi
    done

    # API files
    install -d ${D}/usr/share/legato/interfaces
    cd ${S}
    for file in $(find ./interfaces -name "*.api"); do
        dir=$(dirname $file)
        echo "Installing API: $file"
        if [ "$dir" != "." ]; then
            install -d ${D}/usr/share/legato/$dir
        fi
        install $file ${D}/usr/share/legato/$file
    done
}

do_install_image() {
    export LEGATO_VERSION=$(cat ${D}/usr/share/legato/version)

    # legato-image
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        mkdir -p ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/${target}
        if [ -d ${B}/build/${target}/readOnlyStaging/legato ]; then
            cp -R ${B}/build/${target}/readOnlyStaging/legato/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/${target}/
        else
            cp -R ${B}/build/${target}/staging/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/${target}/
        fi
    done
}

FILES_${PN}-dbg += "usr/local/*/.debug/*"
FILES_${PN}-dbg += "*/.debug/*"

FILES_${PN}-dev += "usr/local/lib/libjansson.so"
FILES_${PN}-dev += "usr/local/lib/libjansson.so.4"

FILES_${PN}-dev += "lib/libjansson.so"
FILES_${PN}-dev += "lib/libjansson.so.4"

FILES_${PN} += "opt/legato/*"
FILES_${PN} += "usr/local/*"
FILES_${PN} += "mnt/legato/*"

INSANE_SKIP_${PN} = "installed-vs-shipped dev-deps dev-so"

