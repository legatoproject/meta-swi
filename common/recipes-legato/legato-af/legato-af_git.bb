DESCRIPTION = "Legato - Application framework"
SECTION = "base"
DEPENDS = "legato-tools"
PR = "r0"

require legato.inc

FILESEXTRAPATHS += "${THISDIR}/files"

LEGATO_ROOT ?= "/mnt/legato"

LEGATO_ROOTFS_TARGETS ?= "ar7 wp7 ar7-ecall"

do_configure[noexec] = "1"

do_prepare_tools() {
    # Remove 'tools' target
    sed -i 's/.PHONY: tools//g' ${S}/Makefile
    sed -i 's/tools:/disabled_tools:/g' ${S}/Makefile
    touch ${S}/tools

    # Prepare bin/
    mkdir -p ${S}/bin
    cd ${S}

    sysval=`uname -m`-linux
    realmk=$(pwd | sed -e "s/armv7a-vfp-neon-poky-linux-gnueabi/$sysval/" | sed -e "s/legato-af/legato-tools/")

    #ln -sf $(which mk) bin/mk
    ln -sf $realmk/bin/mk bin/mk
    ln -sf mk bin/mkif
    ln -sf mk bin/mkcomp
    ln -sf mk bin/mkexe
    ln -sf mk bin/mkapp
    ln -sf mk bin/mksys
    ln -sf ${S}/framework/tools/scripts/* bin/
    ln -sf ${S}/framework/tools/ifgen/ifgen bin/
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

    # Need a special case for European eCall
    if [ "x$TARGET" = "xar7-ecall" ]
    then
        make $TARGET INCLUDE_ECALL=1
    else
        make $TARGET
    fi
}

do_compile() {
    # For some reason this doesn't work in do_unpack_append
    # Need to grab the airvantage module if it isn't there already
    if [ ! -f "${S}/airvantage/CMakeLists.txt" ]
    then
        git submodule init
        git submodule update
    fi

    for target in ${LEGATO_ROOTFS_TARGETS}; do

        # If it is an ar7 target need to handle ecall separately
        if [ $(expr substr $target 1 3) = "ar7" ]
        then
            compile_target ar7
            if [ "x$target" = "xar7" ]
            then
                target_dir=${S}/build/ar7-noecall
            else
                target_dir=${S}/build/ar7-ecall
            fi

            if [ -d ${target_dir} ]
            then
                rm -fr ${target_dir}
            fi

            # Move the build out of the way so that we can 
            # multip[le AR7 variants
            mv ${S}/build/ar7 ${target_dir}
        else
            compile_target $target
        fi
    done
}

ship_target() {
    TARGET=$1
    bzip2 -c ${S}/build/$TARGET/legato-runtime.tar > ${D}/opt/legato/pkgs/$PKG
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

    # Generate the framework images
    targs=`ls -1 ${S}/build`
    for target in ${targs}; do
        rm -fr ${D}/${target}
        mkdir ${D}/${target}
        cp -R ${S}/build/${target}/staging/* ${D}/${target}/
        mkyaffs2image -c 4096 -s 160 ${D}/${target}/ ${DEPLOY_DIR_IMAGE}/legato_af_${target}.yaffs2
    done
}

FILES_${PN} += "opt/legato/*"
FILES_${PN} += "usr/local/*"
FILES_${PN} += "mnt/legato/*"

INSANE_SKIP_${PN} = "installed-vs-shipped"
