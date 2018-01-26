DESCRIPTION = "Legato - Application framework"
SECTION = "base"
PR = "r0"

inherit legato

require legato.inc

# Host dependencies
DEPENDS = "legato-tools"
DEPENDS += "yaffs2-utils-native"
DEPENDS += "squashfs-tools-native"
DEPENDS += "mtd-utils-native"

# Framework dependencies
RDEPENDS_${PN} += "libgcc"
RDEPENDS_${PN} += "libstdc++"

# Target dependencies
DEPENDS += "curl"
DEPENDS += "zlib"
DEPENDS += "tinycbor"
DEPENDS += "openssl"

# Build time dependencies (not in the rootfs image)
do_compile[depends]  = "legato-tools:do_populate_sysroot"
do_compile[depends] += "gdb:do_populate_sysroot"

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

LDFLAGS = ""
TARGET_LDFLAGS = ""

do_configure[noexec] = "1"

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
    local liblegato_inc="${S}/framework/include"
    if [ ! -e "${liblegato_inc}" ]; then
        liblegato_inc="${S}/framework/c/inc"
    fi
    for file in $(find "${liblegato_inc}" -type f); do
        echo "Installing header: $file"
        install $file ${D}${includedir}
    done

    # private headers required by _main.c
    install -d ${D}/usr/share/legato/src
    local liblegato_src="${S}/framework/liblegato"
    if [ ! -e "${liblegato_src}" ]; then
        liblegato_src="${S}/framework/c/src"
    fi
    cd "${liblegato_src}"
    for file in eventLoop.h log.h args.h; do
        [ -e $file ] && install $file ${D}/usr/share/legato/src/
    done

    # liblegato
    install -d ${D}${libdir}
    first_target=$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')
    if [ -n "$first_target" ]; then
        if [ -e "${B}/build/$first_target/bin/lib/liblegato.so" ]; then
            install ${B}/build/$first_target/bin/lib/liblegato.so ${D}${libdir}/liblegato.so
        else
            install ${B}/build/$first_target/framework/lib/liblegato.so ${D}${libdir}/liblegato.so
        fi
    fi

    # Populate liblegato.so in sysroots/
    for target in $(echo ${LEGATO_ROOTFS_TARGETS}); do
        install -d ${D}/usr/share/legato/build/$target/framework/lib
        if [ -e "${B}/build/$target/bin/lib/liblegato.so" ]; then
            install ${B}/build/$target/bin/lib/liblegato.so \
                    ${D}/usr/share/legato/build/$target/framework/lib/liblegato.so
        else
            install ${B}/build/$target/framework/lib/liblegato.so \
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
        elif [ -d ${B}/build/${target}/staging ]; then
            cp -R ${B}/build/${target}/staging/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/${target}/
        elif [ -d ${B}/build/${target}/_staging_system.${target}.update ]; then
            cp -R ${B}/build/${target}/_staging_system.${target}.update/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/${target}/
        else
            echo "Unable to find staging directory"
            exit 1
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

INSANE_SKIP_${PN} = "installed-vs-shipped dev-deps dev-so already-stripped"
INSANE_SKIP_${PN}-dev = "dev-elf"

