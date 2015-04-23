
LEGATO_ROOTFS_TARGETS ?= "localhost"
LEGATO_STAGING_DIR = "${TMPDIR}/work-shared/legato"
LEGATO_STAGING_APP_DIR = "${LEGATO_STAGING_DIR}/usr/local/bin/apps"


# Only depend on legato-af if this is not legato-af
def check_legato_af_dep(d):
    legato_build = d.getVar('PN', True) or False
    if legato_build != "legato-af":
        return "legato-af"
    return ""

DEPENDS += "legato-tools"
DEPENDS += "${@check_legato_af_dep(d)}"

legato_toolchain_env() {
    TARGET=$1

    TOOLCHAIN_DIR_ENV="${TARGET^^}_TOOLCHAIN_DIR"
    TOOLCHAIN_DIR=$(dirname $(which $(echo $CC |awk '{print $1}')))

    TOOLCHAIN_PREFIX_ENV="${TARGET^^}_TOOLCHAIN_PREFIX"
    TOOLCHAIN_PREFIX=$(basename $(echo $CC |awk '{print $1}') | sed 's/gcc//g')

    export ${TOOLCHAIN_DIR_ENV}=$TOOLCHAIN_DIR
    export ${TOOLCHAIN_PREFIX_ENV}=$TOOLCHAIN_PREFIX

    echo "Toolchain Dir: ${TOOLCHAIN_DIR_ENV} $TOOLCHAIN_DIR"
    echo "Toolchain Prefix: ${TOOLCHAIN_PREFIX_ENV} $TOOLCHAIN_PREFIX"
}

do_compile() {
    echo "About to build for targets ${LEGATO_ROOTFS_TARGETS}"

    for LEGATO_TARGET in ${LEGATO_ROOTFS_TARGETS}; do
        echo "Compiling ${PN} for $LEGATO_TARGET"

        # Determine toolchain
        legato_toolchain_env $LEGATO_TARGET

        export LEGATO_ROOT=${PKG_CONFIG_SYSROOT_DIR}/usr/share/legato

        compile_target $LEGATO_TARGET
    done
}

do_install() {
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        # Deploy app package in directory (for manual deployment)
        install -d ${DEPLOY_DIR}/legato/$target
        install ${S}/${LEGATO_APP_NAME}.$target ${DEPLOY_DIR}/legato/$target
    done
}

do_install_image() {
    if [ -z "${LEGATO_APP_NAME}" ]; then
        echo "Skipping ${PN} for legato-image: LEGATO_APP_NAME not set"
        return
    fi

    for target in ${LEGATO_ROOTFS_TARGETS}; do
        # Deploy app package in image
        echo "Shipping ${PN} in legato-image for $target"
        install -d ${LEGATO_STAGING_DIR}/$target/usr/local/bin/apps
        install ${S}/${LEGATO_APP_NAME}.$target ${LEGATO_STAGING_DIR}/$target/usr/local/bin/apps
    done
}

addtask install_image after do_install before do_build

