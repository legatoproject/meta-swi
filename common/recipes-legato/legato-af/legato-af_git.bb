DESCRIPTION = "Legato - Application framework"
SECTION = "base"
DEPENDS = "legato-tools"
PR = "r0"

require legato.inc

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

LEGATO_ROOTFS_TARGETS ?= "ar7,wp7,ar86"

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

toolchain_env() {
    TARGET=$1
    TOOLCHAIN_DIR_ENV="${TARGET^^}_TOOLCHAIN_DIR"
    TOOLCHAIN_DIR=$(dirname $(which $(echo $CC |awk '{print $1}')))

    export ${TOOLCHAIN_DIR_ENV}=$TOOLCHAIN_DIR

    echo "Toolchain: ${TOOLCHAIN_DIR_ENV} $TOOLCHAIN_DIR"
}

compile_target() {
    TARGET=$1

    echo "Building for $TARGET"
    toolchain_env $TARGET

    make $TARGET
}

do_compile() {
    # For some reason this doesn't work in do_unpack_append
    # Need to grab the airvantage module if it isn't there already
    if [ ! -f "${S}/airvantage/CMakeLists.txt" ]
    then
        git submodule init
        git submodule update
    fi

    ROOTFS_TARGS=$(echo ${LEGATO_ROOTFS_TARGETS} | sed -e "s/\,/ /g")
    echo "About to build for targets ${ROOTFS_TARGS}"

    for target in ${ROOTFS_TARGS}; do
        compile_target $target
    done
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
}

FILES_${PN}-dbg += "usr/local/bin/.debug/*"
FILES_${PN}-dbg += "usr/local/lib/.debug/*"

FILES_${PN}-dev += "usr/local/lib/libjansson.so"
FILES_${PN}-dev += "usr/local/lib/libjansson.so.4"

FILES_${PN} += "opt/legato/*"
FILES_${PN} += "usr/local/*"
FILES_${PN} += "mnt/legato/*"

INSANE_SKIP_${PN} = "installed-vs-shipped"

