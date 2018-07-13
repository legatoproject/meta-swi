require recipes-core/meta/meta-toolchain.bb

# Only add Legato if this is a LEGATO_BUILD
def get_toolchain_version(d):
    # Return the SDK prefix (version in /opt/swi)
    # unless it is the default one.
    sdk_prefix_default = d.getVar('SDKPATH_PREFIX_DEFAULT', True)
    sdk_prefix = d.getVar('SDKPATH_PREFIX', True)
    if (not sdk_prefix) or (not sdk_prefix_default):
        raise Exception("Expected sdk_prefix[%s] and sdk_prefix_default[%s], but one of them is not set" % (sdk_prefix, sdk_prefix_default))
    if sdk_prefix != sdk_prefix_default:
        return sdk_prefix
    # Otherwise default to DISTRO_VERSION, a variable define
    # by poky that corresponds to the yocto version (2.2.3 for instance).
    return d.getVar('DISTRO_VERSION', True)

TOOLCHAIN_VERSION = "${@get_toolchain_version(d)}"
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-swi-toolchain"
TOOLCHAIN_TARGET_TASK += "packagegroup-swi-toolchain-target"
TOOLCHAIN_OUTPUTNAME = "${SDK_NAME}-toolchain-swi-${TOOLCHAIN_VERSION}"

SDK_PACKAGING_FUNC_ORIG = "create_shar"
SDK_PACKAGING_FUNC = "create_sdk_pkgs"

# Run 'make scripts' in kernel directory to setup driver builds.
# SUDO_EXEC is blank unless we're installing in non-writable directory,
# otherwise it's '/usr/bin/sudo'. The effect of this is that when
# installing in e.g. $HOME, we execute:
#    /bin/sh -c "( . $target_sdk_dir/environment-setup... ; make scripts )"
# When installing in e.g. /opt, files are extracted by a sudo'ed command
# and owned by sudo user, so we execute the exact same thing, but as root
# since the command is prepended with sudo:
#    sudo /bin/sh -c "( . $target_sdk_dir/environment-setup... ; make scripts )"
#
# Note that $target_sdk_dir doesn't use ${} syntax, and so
# isn't expanded by Poky; it passes literally through to the shell script.
SDK_POST_INSTALL_COMMAND = \
    "( set -e; \
       if cd $target_sdk_dir/sysroots/${REAL_MULTIMACH_TARGET_SYS}${KERNEL_SRC_PATH} && [ -e Makefile ] ; then \
         $SUDO_EXEC /bin/sh -c "( \
           . $target_sdk_dir/environment-setup-${REAL_MULTIMACH_TARGET_SYS}; \
           make scripts; \
         )"; \
       fi ); \
       if [ $? -ne 0 ] ; then \
         echo \"Failed to install driver build environment.\"; \
         exit 1; \
       fi"

repack_tarball() {
    TARBALL_XZ="${SDKDEPLOYDIR}/${TOOLCHAIN_OUTPUTNAME}.tar.xz"

    SDK_STAGE_DIR="${WORKDIR}/swistage"

    echo "Create new staging dir"
    if [ -e "$SDK_STAGE_DIR" ]; then
        rm -rf $SDK_STAGE_DIR
    fi

    mkdir $SDK_STAGE_DIR
    cd $SDK_STAGE_DIR

    echo "Extract SDK"
    tar Jxf $TARBALL_XZ

    echo "Backup tarball"
    mv $TARBALL_XZ "$TARBALL_XZ.orig"

    ROOT_DIR=$(basename ${SDKPATH})

    echo "Moving to $ROOT_DIR"

    mkdir $ROOT_DIR
    mv sysroots $ROOT_DIR

    echo "Recreate tarball '$TARBALL_XZ'"
    tar ${SDKTAROPTS} -cf - $ROOT_DIR | xz -T 0 > $TARBALL_XZ

    echo "Moving '$TARBALL_XZ' to '$TARBALL_XZ.repkg'"
    mv $TARBALL_XZ "$TARBALL_XZ.repkg"
    mv "$TARBALL_XZ.orig" $TARBALL_XZ
}

move_repacked() {
    TARBALL_XZ="${SDKDEPLOYDIR}/${TOOLCHAIN_OUTPUTNAME}.tar.xz"

    echo "Moving '$TARBALL_XZ.repkg' to '$TARBALL_XZ'"
    mv "$TARBALL_XZ.repkg" $TARBALL_XZ
}

python create_sdk_pkgs() {
    bb.build.exec_func("repack_tarball", d)
    bb.build.exec_func("create_shar", d)
    bb.build.exec_func("move_repacked", d)
}
