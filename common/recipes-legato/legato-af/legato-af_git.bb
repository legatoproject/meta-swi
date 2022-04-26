DESCRIPTION = "Legato - Application framework"
SECTION = "base"
PR = "r0"

inherit legato

require legato.inc

# Host dependencies
DEPENDS += "autoconf-native"
DEPENDS += "squashfs-tools-native"
DEPENDS += "mtd-utils-native"
DEPENDS += "ima-support-tools-native"
DEPENDS += "ima-evm-utils-native"
DEPENDS += "libarchive-native"
DEPENDS += "bsdiff-native"

# Framework dependencies
RDEPENDS:${PN} += "libgcc"
RDEPENDS:${PN} += "libstdc++"

# Optional framework support
PACKAGECONFIG ??= "nopython"
PACKAGECONFIG[python3] = "python3,nopython,python3"

# Target dependencies
DEPENDS += "curl"
DEPENDS += "zlib"
DEPENDS += "openssl"

# Sample apps dependencies
DEPENDS += "procps"

# Build time dependencies (not in the rootfs image)
do_compile[depends]  = "legato-tools-native:do_populate_sysroot"
do_compile[depends] += "gdb:do_populate_sysroot"

# Add dependency to the kernel so that Legato can build kernel modules.
do_compile[depends] += "dummy-kernel-mod:do_compile"

# Always compile; there are generated files (version) that affect the output.
# stamps cannot trace generated files.
do_compile[nostamp] = "1"

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

LDFLAGS = ""
TARGET_LDFLAGS = ""

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_configure[noexec] = "1"

compile_target() {
    make $LEGATO_TARGET ENABLE_IMA=${ENABLE_IMA} IMA_PRIVATE_KEY=${IMA_PRIVATE_KEY} IMA_PUBLIC_CERT=${IMA_PUBLIC_CERT}
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
            select_legato_target $target
            find ${B}/build/$LEGATO_TARGET/staging/mnt/flash/startupDefaults -type f -exec install "{}" "${D}/opt/legato/startupDefaults/" \;
        done
    fi

    # headers
    install -d ${D}${includedir}
    local liblegato_inc="${S}/framework/include"
    if [ ! -e "${liblegato_inc}" ]; then
        liblegato_inc="${S}/framework/c/inc"
    fi
    (cd ${liblegato_inc} && find . -type f -exec echo "Installing header: {}" \; -exec install "{}" -D "${D}${includedir}/{}" \;)

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
        select_legato_target $first_target

        if [ -e "${B}/build/$LEGATO_TARGET/bin/lib/liblegato.so" ]; then
            install ${B}/build/$LEGATO_TARGET/bin/lib/liblegato.so ${D}${libdir}/liblegato.so
        else
            install ${B}/build/$LEGATO_TARGET/framework/lib/liblegato.so ${D}${libdir}/liblegato.so
        fi
    fi

    # Populate liblegato.so and config in sysroots/
    for target in $(echo ${LEGATO_ROOTFS_TARGETS}); do
        select_legato_target $target

        install -d ${D}/usr/share/legato/build/$LEGATO_TARGET/framework/lib
        if [ -e "${B}/build/$LEGATO_TARGET/bin/lib/liblegato.so" ]; then
            install ${B}/build/$LEGATO_TARGET/bin/lib/liblegato.so \
                    ${D}/usr/share/legato/build/$LEGATO_TARGET/framework/lib/liblegato.so
        else
            install ${B}/build/$LEGATO_TARGET/framework/lib/liblegato.so \
                    ${D}/usr/share/legato/build/$LEGATO_TARGET/framework/lib/liblegato.so
        fi

        if [ -e "${B}/build/$LEGATO_TARGET/config.sh" ]; then
            install ${B}/build/$LEGATO_TARGET/config.sh \
                    ${D}/usr/share/legato/build/$LEGATO_TARGET/config.sh
        fi
        install -d ${D}/usr/share/legato/build/$LEGATO_TARGET/framework/include
        if [ -e "${B}/build/$LEGATO_TARGET/framework/include/le_config.h" ]; then
            install ${B}/build/$LEGATO_TARGET/framework/include/le_config.h \
                    ${D}/usr/share/legato/build/$LEGATO_TARGET/framework/include/le_config.h
        fi
    done

    # API files
    (cd ${S} && find ./interfaces -name "*.api" -exec echo "Installing API: {}" \; -exec install "{}" -D "${D}/usr/share/legato/{}" \;)
}

do_install_image() {
    export LEGATO_VERSION=$(cat ${D}/usr/share/legato/version)

    # legato-image
    rm -rf "${LEGATO_STAGING_DIR}/$LEGATO_VERSION"
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        select_legato_target $target

        mkdir -p ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$target
        if [ -d ${B}/build/$LEGATO_TARGET/readOnlyStaging/legato ]; then
            cp -R ${B}/build/$LEGATO_TARGET/readOnlyStaging/legato/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$target/
        elif [ -d ${B}/build/$LEGATO_TARGET/staging ]; then
            cp -R ${B}/build/$LEGATO_TARGET/staging/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$target/
        elif [ -d ${B}/build/$LEGATO_TARGET/_staging_system.$LEGATO_TARGET.update ]; then
            cp -R ${B}/build/$LEGATO_TARGET/_staging_system.$LEGATO_TARGET.update/* ${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$target/
        else
            echo "Unable to find staging directory"
            exit 1
        fi
    done
}

FILES:${PN}-dbg += "usr/local/*/.debug/*"
FILES:${PN}-dbg += "*/.debug/*"

FILES:${PN}-dev += "usr/local/lib/libjansson.so"
FILES:${PN}-dev += "usr/local/lib/libjansson.so.4"

FILES:${PN}-dev += "lib/libjansson.so"
FILES:${PN}-dev += "lib/libjansson.so.4"

FILES:${PN} += "opt/legato/*"
FILES:${PN} += "usr/local/*"
FILES:${PN} += "mnt/legato/*"

INSANE_SKIP:${PN} = "installed-vs-shipped dev-deps dev-so already-stripped"
INSANE_SKIP:${PN}-dev = "dev-elf"

