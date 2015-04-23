require recipes-core/meta/meta-toolchain.bb

TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-swi-toolchain"
TOOLCHAIN_TARGET_TASK += "packagegroup-swi-toolchain-target"
TOOLCHAIN_OUTPUTNAME = "${SDK_NAME}-toolchain-swi-${DISTRO_VERSION}"

SDK_PACKAGING_FUNC_ORIG = "create_shar"
SDK_PACKAGING_FUNC = "create_sdk_pkgs"

repack_tarball() {
    TARBALL_BZ="${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.tar.bz2"
    TARBALL="${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.tar"

    SDK_STAGE_DIR="${WORKDIR}/swistage"

    echo "Create new staging dir"
    if [ -e "$SDK_STAGE_DIR" ]; then
        rm -rf $SDK_STAGE_DIR
    fi

    mkdir $SDK_STAGE_DIR
    cd $SDK_STAGE_DIR

    echo "Extract SDK"
    tar jxf $TARBALL_BZ

    echo "Backup tarball"
    mv $TARBALL_BZ "$TARBALL_BZ.orig"

    ROOT_DIR=$(basename ${SDKPATH})

    echo "Moving to $ROOT_DIR"

    mkdir $ROOT_DIR
    mv sysroots $ROOT_DIR

    echo "Recreate tarball '$TARBALL_BZ'"
    tar jcf $TARBALL_BZ $ROOT_DIR

    echo "Moving '$TARBALL_BZ' to '$TARBALL_BZ.repkg'"
    mv $TARBALL_BZ "$TARBALL_BZ.repkg"
    mv "$TARBALL_BZ.orig" $TARBALL_BZ
}

move_repacked() {
    TARBALL_BZ="${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.tar.bz2"

    echo "Moving '$TARBALL_BZ.repkg' to '$TARBALL_BZ'"
    mv "$TARBALL_BZ.repkg" $TARBALL_BZ
}

python create_sdk_pkgs() {
    bb.build.exec_func("repack_tarball", d)
    bb.build.exec_func("create_shar", d)
    bb.build.exec_func("move_repacked", d)
}
