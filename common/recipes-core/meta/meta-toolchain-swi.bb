require recipes-core/meta/meta-toolchain.bb

TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-swi-toolchain"
TOOLCHAIN_TARGET_TASK += "packagegroup-swi-toolchain-target"
TOOLCHAIN_OUTPUTNAME = "${SDK_NAME}-toolchain-swi-${DISTRO_VERSION}"

SDK_PACKAGING_FUNC_ORIG = "create_shar"
SDK_PACKAGING_FUNC = "create_sdk_pkgs"

# Note that $target_sdk_dir is doesn't use ${} syntax, and so
# isn't expanded by Poky; it passes literally through to the shell script.
SDK_POST_INSTALL_COMMAND = \
    "( if cd $target_sdk_dir/sysroots/${REAL_MULTIMACH_TARGET_SYS}${KERNEL_SRC_PATH} && [ -e Makefile ] ; then \
         . $target_sdk_dir/environment-setup-${REAL_MULTIMACH_TARGET_SYS}; \
         [ -n "$SUDO_EXEC" ] && $SUDO_EXEC find scripts -type d -exec chown -R $(id -u) {} \; ; \
         make ARCH=${ARCH} scripts; \
         [ -n "$SUDO_EXEC" ] && $SUDO_EXEC find scripts -exec chown -R 0 {} \; ; \
       fi )"

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
    tar ${SDKTAROPTS} -cf - $ROOT_DIR | pixz > $TARBALL_XZ

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
