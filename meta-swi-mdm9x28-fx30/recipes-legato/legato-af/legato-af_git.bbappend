
do_compile_prepend() {
    # Check to see if $LEGATO_VERSION has already been defined
    if [ -z "${LEGATO_VERSION}"]; then
        # If it has not, build a unique string for the version
        echo "Building FX30 Legato version string"
        cd ${S}

        # Get the major Legato version
        FX30_LEGATO_MAJOR_VERSION=$(git describe --tags)
        echo "Legato major version: ${FX30_LEGATO_MAJOR_VERSION}"

        # Compile a list of all the things we'll use for the hash
        # The basis of this algorithm was lifted from the Legato source:
        # legato/framework/tools/mkTools/buildScriptGenerator/systemBuildScript.cpp:136
        FX30_SOURCE_HASH_CONTENTS=$(
            date &&
            find -P -print0 | LC_ALL=C sort -z &&
            find -P -type f -print0 | LC_ALL=C sort -z | xargs -0 sh -c 'for file do md5sum "$file"; date; done' &&
            find -P -type l -print0 | LC_ALL=C sort -z | xargs -0 -r -n 1 readlink)

        # Generate a hash of the item list
        FX30_HASH_STRING=$(echo ${FX30_SOURCE_HASH_CONTENTS} | md5sum | cut -d ' ' -f 1)
        echo "FX30 Legato source hash string: ${FX30_HASH_STRING}"

        # Get the last 8 digits of the hash
        FX30_SHORT_HASH_STRING=$(echo "${FX30_HASH_STRING: -8}")
        echo "Legato source short hash: ${FX30_SHORT_HASH_STRING}"
        echo ${FX30_SHORT_HASH_STRING} > ${WORKDIR}/columbia_short_hash

        # Build the version string Legato will be built with
        LEGATO_VERSION="${FX30_LEGATO_MAJOR_VERSION}.${FX30_SHORT_HASH_STRING}"
        echo "FX30 Legato version: ${LEGATO_VERSION}"

        export LEGATO_VERSION
    else
        # If it has, let Legato use it
        echo "LEGATO_VERSION already defined: ${LEGATO_VERSION}"
    fi
}

# Copies "columbia_short_hash" to DEPLOY_DIR_IMAGE
do_deploy() {
    mkdir -p ${DEPLOY_DIR_IMAGE}

    cp ${WORKDIR}/columbia_short_hash ${DEPLOY_DIR_IMAGE}
}
addtask deploy after do_install

# Prevent the setscene task from copying the cached legato version into the sysroots folder
deltask do_populate_sysroot_setscene
