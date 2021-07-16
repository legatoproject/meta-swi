# This bbclass generates version files as part of the rootfs image generation.
# It relies on few functions to retreive versions for various components in the system
# (poky, meta-swi, kernel, ...).
#
# It is possible to extend the version file with other components by appending $DST in function
# do_generate_version_file, generally through a do_generate_version_file_append located in
# a xxxx-image-minimal.bbappend.

determine_rootfs_version() {

    if [ -n "${ROOTFS_VERSION}" ]; then
        echo "Using ROOTFS_VERSION: ${ROOTFS_VERSION}"
        export VERSION_rootfs="${ROOTFS_VERSION}"
        return
    fi

    # Otherwise fallback on fw version or meta-swi version
    if [ -n "$VERSION_fw" ]; then
        export VERSION_rootfs="$VERSION_fw"
    else
        cd $meta_swi_dir
        export VERSION_rootfs="$(git rev-parse --short HEAD)"
    fi
}

determine_fw_version() {

    # Firmware
    if echo ${BBLAYERS} | grep -E "meta-swi-.*-bin"; then
        # meta-swi-bin: Use fw-version

        swi_bin_dir=$(echo "${BBLAYERS}" | tr ' ' '\n' | grep -E "meta-swi-.*-bin" | uniq)
        export VERSION_fw=$(cat $swi_bin_dir/files/fw-version)
    elif echo ${BBLAYERS} | grep -E "meta-swi-.*-src"; then
        # meta-swi-src

        if [ -n "${FW_VERSION}" ]; then
            echo "Using FW_VERSION: ${FW_VERSION}"
            export VERSION_fw=${FW_VERSION}
            return
        fi

        if [ -d "${WORKSPACE}" ]; then
            cd ${WORKSPACE}

            # Try git first
            if git rev-parse HEAD; then
                git_rev=$(git describe --tags || true)
                if [ -n "$git_rev" ]; then
                    export VERSION_fw="$git_rev (from '${WORKSPACE}')"
                else
                    git_rev=$(git rev-parse --short HEAD)
                    export VERSION_fw="$git_rev (from '${WORKSPACE}')"
                fi
            # Try svn
            elif svn status --depth=empty ; then
                # Provide SVN revision
                svn_rev=$(svnversion)
                if [ $? -eq 0 ]; then
                    export VERSION_fw="r$svn_rev"
                fi
            fi
        fi

        if [ -z "$VERSION_fw" ]; then
            export VERSION_fw="unknown (from '${WORKSPACE}')"
        fi
    fi
}

determine_kernel_versions() {
    cd "${IMGDEPLOYDIR}"

    if [ ! -e "${IMAGE_MANIFEST}" ]; then
        echo "Image manifest does not exist."
        exit 1
    fi

    # Retreive generic version name from manifest
    VERSION_kernel_image=$(grep -e '^kernel' "${IMAGE_MANIFEST}" | grep -v 'module' \
                                                                 | awk '{print $3}' \
                                                                 | sed 's/-r[0-9]*$//' \
                                                                 | head -1)

    # linux-yocto
    if [[ "${PREFERRED_PROVIDER_virtual/kernel}" == "linux-yocto" ]]; then
        kernel_versions=$(echo "${VERSION_kernel_image}" | grep -Po '\+([\w]{6,})_([\w]{6,})' | sed 's/[+_]/ /g')
        kernel_meta_rev=$(echo $kernel_versions |awk '{print $1}')
        kernel_machine_rev=$(echo $kernel_versions |awk '{print $2}')
        VERSION_kernel_meta="$kernel_meta_rev"
        VERSION_kernel_machine="$kernel_machine_rev"
        VERSION_kernel=$(echo ${PREFERRED_VERSION_linux-yocto} | sed 's/%//g')

    # linux-quic
    elif [[ "${PREFERRED_PROVIDER_virtual/kernel}" == "linux-quic" ]]; then
        VERSION_kernel=$(echo ${PREFERRED_VERSION_linux-quic} | sed 's/%//g')

    # linux-msm
    elif [[ "${PREFERRED_PROVIDER_virtual/kernel}" == "linux-msm" ]]; then
        VERSION_kernel=$(echo ${PREFERRED_VERSION_linux-msm} | sed 's/%//g')
    fi

    if [ -z "$VERSION_kernel" ]; then
        echo "Unable to determine kernel version"
        exit 1
    fi
}

do_generate_version_file() {
    set -x

    DST="${IMAGE_ROOTFS}/etc/legato/version"
    ROOTFS_DST="${IMAGE_ROOTFS}/etc/rootfsver.txt"

    mkdir -p "$(dirname ${DST})"

    gen_date=$(date +%F_%T)

    # poky
    poky_dir=$(echo ${BBLAYERS} |tr ' ' '\n' |grep poky |head -1)
    VERSION_poky=$(cd $poky_dir && git describe --tags --match="yocto*")

    # meta-oe
    meta_oe_dir=$(echo ${BBLAYERS} |tr ' ' '\n' |grep -E "meta-oe$")
    VERSION_meta_oe=$(cd $meta_oe_dir && git rev-parse --short HEAD)

    # meta-swi
    if echo ${BBLAYERS} | grep "meta-swi/common"; then
        meta_swi_dir=$(echo ${BBLAYERS} |tr ' ' '\n' |grep -E "meta-swi/common$")
    else
        meta_swi_dir=$(echo ${BBLAYERS} |tr ' ' '\n' |grep -E "meta-swi$")
    fi
    cd $meta_swi_dir
    VERSION_meta_swi=$(git rev-parse --short HEAD)

    # meta-swi-extras
    if [ -n "${META_SWI_EXTRAS_DIR}" ]; then
        cd ${META_SWI_EXTRAS_DIR}
        VERSION_meta_swi_extras=$(git rev-parse --short HEAD)
    fi

    determine_kernel_versions

    determine_fw_version
    echo "Firmware Version: $VERSION_fw"

    determine_rootfs_version
    echo "RootFS Version: $VERSION_rootfs"

    # Main version file

    rm -f $DST
    echo "Build created at $gen_date" >> $DST
    echo "" >> $DST
    echo "Yocto build version: $VERSION_rootfs" >> $DST
    echo "" >> $DST
    echo "Build host: $(hostname)" >> $DST
    echo "Versions:" >> $DST
    if [ -n "${VERSION_fw}" ]; then
        echo " - firmware: $VERSION_fw" >> $DST
    fi
    echo " - poky: ${VERSION_poky}" >> $DST
    echo " - meta-openembedded: ${VERSION_meta_oe}" >> $DST
    echo " - meta-swi: ${VERSION_meta_swi}" >> $DST
    if [ -n "${VERSION_meta_swi_extras}" ]; then
        echo " - meta-swi-extras: ${VERSION_meta_swi_extras}" >> $DST
    fi
    if [ -n "${VERSION_kernel_image}" ]; then
        echo " - ${PREFERRED_PROVIDER_virtual/kernel}-${VERSION_kernel}: ${VERSION_kernel_image}" >> $DST
    fi
    if [[ "${PREFERRED_PROVIDER_virtual/kernel}" == "linux-yocto" ]]; then
        echo " - ${PREFERRED_PROVIDER_virtual/kernel}-${VERSION_kernel}/meta: ${VERSION_kernel_meta}" >> $DST
        echo " - ${PREFERRED_PROVIDER_virtual/kernel}-${VERSION_kernel}/machine: ${VERSION_kernel_machine}" >> $DST
    fi

    cat $DST

    # RootFS version file

    echo "$VERSION_rootfs $gen_date" > $ROOTFS_DST

    cat $ROOTFS_DST
}

# Inject the version file in the rootfs directory before it
# is being packaged into an image.
IMAGE_PREPROCESS_COMMAND += "do_generate_version_file; "

do_copy_swi_version() {
    cd ${DEPLOY_DIR_IMAGE}
    cp ${IMAGE_ROOTFS}/etc/legato/version ${IMAGE_NAME}.build_package.version
    ln -sf ${IMAGE_NAME}.build_package.version ${IMAGE_LINK_NAME}.build_package.version
    ln -sf ${IMAGE_NAME}.build_package.version build_package.version

    TMP_VERSION=$(cat build_package.version | grep "build version" | cut -d' ' -f4)
    TMP_TIME=$(cat build_package.version | grep "Build created" | cut -d' ' -f4 | sed -r 's/-/\//g' | sed -r 's/_/ /g')
    echo "$TMP_VERSION $TMP_TIME" >> ${IMAGE_NAME}.rootfs.version
    ln -sf ${IMAGE_NAME}.rootfs.version ${IMAGE_LINK_NAME}.rootfs.version
    ln -sf ${IMAGE_NAME}.rootfs.version rootfs.version
}

addtask copy_swi_version after do_image_complete before do_build

